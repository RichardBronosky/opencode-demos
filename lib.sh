#!/usr/bin/env bash
# lib.sh — shared helpers for all act run scripts and build.sh

ZSCALER_CERT_HOST="/etc/ssl/certs/zscaler-root-ca.pem"
DEMO_IMAGE="opencode-demo:latest"
DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_SOCKET="/tmp/tmux-$(id -u)/default"

# Aliases are not exported to subshells, so 'docker' may only exist as an alias
# in the user's interactive shell (e.g. aliased to podman). Detect the real binary.
DOCKER=$(command -v docker 2>/dev/null || command -v podman 2>/dev/null || true)
if [[ -z "$DOCKER" ]]; then
  echo "ERROR: neither docker nor podman found in PATH." >&2
  exit 1
fi

# Rootless Podman maps container uid=1000 to a subuid range on the host, not to
# the real host uid. This makes host-mounted volume directories appear unwritable
# inside the container unless we pass --userns=keep-id, which maps the container
# user to the same uid as the invoking host user. Docker does not support this
# flag, so only set it when using Podman.
USERNS_ARGS=()
if [[ "$(basename "$DOCKER")" == "podman" ]]; then
  USERNS_ARGS=(--userns=keep-id)
fi

# Offer to open a fresh terminal window.
# On WSL, uses Windows Terminal (wt.exe).
# On Linux, detects the first available graphical terminal emulator.
# The caller describes what the new window should be used for.
offer_terminal() {
  local purpose="${1:-run this script}"
  local term_cmd="" term_name="" launch_args=()

  # WSL: prefer Windows Terminal
  if grep -qi microsoft /proc/version 2>/dev/null && command -v wt.exe &>/dev/null; then
    term_cmd="wt.exe"
    term_name="wt.exe"
    launch_args=(--size 100,40)
  # Native Linux: need a graphical session and a known terminal emulator
  elif [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    for candidate in alacritty kitty gnome-terminal konsole xfce4-terminal lxterminal urxvt xterm; do
      if command -v "$candidate" &>/dev/null; then
        term_cmd="$candidate"
        term_name="$candidate"
        case "$candidate" in
          alacritty)
            launch_args=(--option 'window.dimensions.columns=220' --option 'window.dimensions.lines=50')
            ;;
          kitty)
            launch_args=(--override initial_window_width=220c --override initial_window_height=50c)
            ;;
          gnome-terminal)
            launch_args=(--geometry=220x50)
            ;;
          konsole|xfce4-terminal|lxterminal|urxvt|xterm)
            launch_args=(-geometry 220x50)
            ;;
        esac
        break
      fi
    done
  fi

  [[ -z "$term_cmd" ]] && return 0

  echo ""
  echo "A fresh terminal window may be useful to ${purpose}."
  printf "Open one now? (%s) [y/N] " "$term_name"
  read -r reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    "$term_cmd" "${launch_args[@]}" &>/dev/null &
    disown
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
    $DOCKER run --rm "${USERNS_ARGS[@]}" -v "${dir}:/fix" ubuntu:24.04 chown -R "$(id -u)" /fix
  fi
}

# Build the shared demo image (cached after first run).
# Copies Zscaler cert into build context if present on the host.
# Passes the current user's UID so the in-container user matches the tmux socket owner.
build_image() {
  local extra_args=()

  if [[ -f "$ZSCALER_CERT_HOST" ]]; then
    echo "=== Zscaler detected on host: injecting root CA into build ==="
    extra_args=(--build-arg "ZSCALER_CERT_B64=$(base64 -w0 "$ZSCALER_CERT_HOST")")
  fi

  $DOCKER build -t "$DEMO_IMAGE" --build-arg HOST_UID="$(id -u)" "${extra_args[@]}" "$DEMO_DIR"
}

# Check that the demo image exists; print a helpful error and return 1 if not.
# Acts call this instead of build_image — building is a separate prerequisite step.
require_image() {
  if ! $DOCKER image inspect "$DEMO_IMAGE" &>/dev/null; then
    echo "ERROR: Docker image '${DEMO_IMAGE}' not found." >&2
    echo "       Build it first:  bash build.sh" >&2
    return 1
  fi
}
