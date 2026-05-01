#!/usr/bin/env bash
# ACT 3: OpenCode in Docker with a local Ollama model — no cloud, no credentials
#
# Prerequisite: the demo Docker image must be built first.
#   bash build.sh
#
# Also requires Ollama to be running on the host with the model pulled.
# See act3/PREREQS.md for the one-time setup.
#
# Runs opencode inside the demo container using --network=host so the container
# can reach Ollama at localhost:11434 on the WSL host without any extra routing.
#
# Usage: bash act3/run.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL="qwen2.5-coder:1.5b"

source "${SCRIPT_DIR}/../lib.sh"

require_image || exit 1

# ── Check 1: Ollama reachable ─────────────────────────────────────────────────
if ! curl -sf http://localhost:11434 &>/dev/null; then
  if ! command -v ollama &>/dev/null; then
    echo "ERROR: ollama is not installed and not running on localhost:11434." >&2
    echo "       See:  ${SCRIPT_DIR}/PREREQS.md" >&2
    exit 1
  fi
  printf "Ollama is not running. Start it now? [y/N] "
  read -r reply
  if [[ ! "$reply" =~ ^[Yy]$ ]]; then
    echo "ERROR: Ollama is not running. Run 'OLLAMA_HOST=0.0.0.0 ollama serve' and try again." >&2
    exit 1
  fi
  echo "  Starting ollama serve (background)..."
  OLLAMA_HOST=0.0.0.0 ollama serve &>/dev/null &
  attempts=0
  while (( attempts < 20 )); do
    curl -sf http://localhost:11434 &>/dev/null && break
    sleep 0.5
    (( attempts++ ))
  done
  if ! curl -sf http://localhost:11434 &>/dev/null; then
    echo "ERROR: ollama serve did not become ready in time." >&2
    exit 1
  fi
  echo "  Ollama is ready."
fi

# ── Check 2: Ollama bound to 0.0.0.0 ─────────────────────────────────────────
# Docker on WSL2 does not share the host loopback with containers.
# Even with --network=host, 127.0.0.1 inside the container is the container's
# own loopback — not the host's. Ollama must listen on 0.0.0.0.
if ss -tlnp 2>/dev/null | grep -q '127.0.0.1:11434' && \
   ! ss -tlnp 2>/dev/null | grep -E -q '0\.0\.0\.0:11434|\*:11434'; then
  echo "" >&2
  echo "ERROR: Ollama is running but bound to 127.0.0.1 only." >&2
  echo "       Docker containers on WSL2 cannot reach it at that address." >&2
  echo "" >&2
  if systemctl is-active ollama &>/dev/null; then
    echo "       Ollama is managed by systemd. To fix permanently:" >&2
    echo "         sudo systemctl edit ollama" >&2
    echo "       Add these two lines, save, then restart:" >&2
    echo "         [Service]" >&2
    echo "         Environment=\"OLLAMA_HOST=0.0.0.0\"" >&2
    echo "         sudo systemctl restart ollama" >&2
  else
    echo "       Stop Ollama and restart it with:" >&2
    echo "         OLLAMA_HOST=0.0.0.0 ollama serve" >&2
  fi
  echo "" >&2
  echo "       See: ${SCRIPT_DIR}/PREREQS.md" >&2
  exit 1
fi

# ── Check 3: Model is pulled ──────────────────────────────────────────────────
if ! ollama list 2>/dev/null | grep -q "^${MODEL}"; then
  echo "ERROR: Model '${MODEL}' is not pulled." >&2
  echo "       Run:  ollama pull ${MODEL}" >&2
  echo "       See:  ${SCRIPT_DIR}/PREREQS.md" >&2
  exit 1
fi

echo "=== Act 3: OpenCode + local model (${MODEL}) ==="
echo "    No tokens leave this machine."
echo ""

$DOCKER run -it --rm "${USERNS_ARGS[@]}" \
  --network=host \
  -v "${SCRIPT_DIR}/config/opencode:/home/oc/.config/opencode" \
  "$DEMO_IMAGE"
