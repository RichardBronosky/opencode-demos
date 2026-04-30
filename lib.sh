#!/usr/bin/env bash
# lib.sh — shared helpers for all act run scripts and build.sh

ZSCALER_CERT_HOST="/etc/ssl/certs/zscaler-root-ca.pem"
DEMO_IMAGE="opencode-demo:latest"
DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_SOCKET="/tmp/tmux-$(id -u)/default"

# If running in WSL, offer to open a fresh Windows Terminal window.
# The caller describes what the new window should be used for.
offer_terminal() {
  local purpose="${1:-run this script}"
  grep -qi microsoft /proc/version 2>/dev/null || return 0
  command -v wt.exe &>/dev/null || return 0
  echo ""
  echo "A fresh Terminal window may be useful to ${purpose}."
  printf "Open one now? (wt.exe --size 100,40) [y/N] "
  read -r reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    wt.exe --size 100,40
  fi
  echo ""
}

# Ensure a host directory exists and is owned by the current user.
# Uses a throwaway docker container if the dir is root-owned (created by a prior root container).
ensure_owned() {
  local dir="$1"
  mkdir -p "$dir"
  if [[ "$(stat -c '%u' "$dir")" != "$(id -u)" ]]; then
    echo "=== Fixing ownership of ${dir} ==="
    docker run --rm -v "${dir}:/fix" ubuntu:24.04 chown -R "$(id -u)" /fix
  fi
}

# Build the shared demo image (cached after first run).
# Copies Zscaler cert into build context if present on the host.
# Passes the current user's UID so the in-container user matches the tmux socket owner.
build_image() {
  local zscaler_tmp="${DEMO_DIR}/zscaler-root-ca.crt"
  local copied=0

  if [[ -f "$ZSCALER_CERT_HOST" ]]; then
    echo "=== Zscaler detected on host: injecting root CA into build context ==="
    cp "$ZSCALER_CERT_HOST" "$zscaler_tmp"
    copied=1
  fi

  docker build -t "$DEMO_IMAGE" --build-arg HOST_UID="$(id -u)" "$DEMO_DIR"
  local ret=$?

  # Clean up temp cert from build context regardless of build outcome
  [[ "$copied" == "1" ]] && rm -f "$zscaler_tmp"

  return $ret
}

# Check that the demo image exists; print a helpful error and return 1 if not.
# Acts call this instead of build_image — building is a separate prerequisite step.
require_image() {
  if ! docker image inspect "$DEMO_IMAGE" &>/dev/null; then
    echo "ERROR: Docker image '${DEMO_IMAGE}' not found." >&2
    echo "       Build it first:  bash build.sh" >&2
    return 1
  fi
}
