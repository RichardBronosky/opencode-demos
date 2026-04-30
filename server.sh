#!/usr/bin/env bash
# server.sh — manage the demo documentation web server
#
# Runs python3 -m http.server inside Docker, serving the repo at http://localhost:8000
#
# Usage:
#   bash server.sh              # start server (if not running) + open browser
#   bash server.sh start        # start server in background
#   bash server.sh stop         # stop server
#   bash server.sh restart      # stop + start
#   bash server.sh status       # show running/stopped state
#   bash server.sh logs         # tail container logs
#   bash server.sh open         # open browser (server must be running)
#   bash server.sh doctor       # check prerequisites

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Aliases are not exported to subshells, so 'docker' may only exist as an alias
# in the user's interactive shell (e.g. aliased to podman). Detect the real binary.
DOCKER=$(command -v docker 2>/dev/null || command -v podman 2>/dev/null || true)
if [[ -z "$DOCKER" ]]; then
  echo "ERROR: neither docker nor podman found in PATH." >&2
  exit 1
fi

CONTAINER_NAME="oc-demo-web"
PORT=8000
# Use 127.0.0.1 explicitly — podman's passt backend accepts IPv6 connections
# on [::1] but immediately resets them; IPv4 is the only reliable loopback.
URL="http://127.0.0.1:${PORT}/"

# ── helpers ────────────────────────────────────────────────────────────────────

is_running() {
  $DOCKER inspect --format '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null | grep -q '^true$'
}

container_exists() {
  $DOCKER inspect "$CONTAINER_NAME" &>/dev/null
}

open_browser() {
  # WSL: prefer wslview, fall back to explorer.exe
  if grep -qi microsoft /proc/version 2>/dev/null; then
    if command -v wslview &>/dev/null; then
      wslview "$URL"
    else
      explorer.exe "$URL"
    fi
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$URL"
  elif command -v open &>/dev/null; then
    open "$URL"
  else
    echo "  Browser not opened — visit: ${URL}"
  fi
}

# ── commands ───────────────────────────────────────────────────────────────────

cmd_doctor() {
  echo "=== Doctor ==="
  local ok=1

  if command -v docker &>/dev/null || command -v podman &>/dev/null; then
    echo "  [OK] container engine found: $DOCKER ($($DOCKER --version))"
  else
    echo "  [FAIL] neither docker nor podman found"
    ok=0
  fi

  if $DOCKER info &>/dev/null; then
    echo "  [OK] Docker daemon is running"
  else
    echo "  [FAIL] Docker daemon is not running"
    ok=0
  fi

  if command -v python3 &>/dev/null; then
    echo "  [OK] python3 found (host): $(python3 --version)"
  else
    echo "  [NOTE] python3 not found on host (not required — server runs in Docker)"
  fi

  # Check port availability (only if server is not already running)
  if ! is_running; then
    if ss -tlnp "sport = :${PORT}" 2>/dev/null | grep -q ":${PORT}"; then
      echo "  [WARN] Port ${PORT} is already in use on the host"
    else
      echo "  [OK] Port ${PORT} is available"
    fi
  else
    echo "  [OK] Server is currently running on port ${PORT}"
  fi

  echo ""
  if [[ "$ok" == "1" ]]; then
    echo "  All checks passed."
  else
    echo "  One or more checks failed — fix the issues above before starting the server."
  fi
}

cmd_status() {
  if is_running; then
    echo "  [RUNNING]  ${URL}"
    echo ""
    $DOCKER ps --filter "name=^${CONTAINER_NAME}$" --format "  container: {{.ID}}  uptime: {{.Status}}"
  elif container_exists; then
    echo "  [STOPPED]  Container '${CONTAINER_NAME}' exists but is not running."
    echo "             Run: bash server.sh start"
  else
    echo "  [STOPPED]  No container named '${CONTAINER_NAME}'."
    echo "             Run: bash server.sh start"
  fi
}

cmd_start() {
  if is_running; then
    echo "  Server is already running at ${URL}"
    return 0
  fi

  # Remove a stopped container with the same name so the engine doesn't conflict
  if container_exists; then
    echo "  Removing stopped container '${CONTAINER_NAME}'..."
    $DOCKER rm "$CONTAINER_NAME" &>/dev/null
  fi

  echo "  Starting web server..."
  $DOCKER run -d \
    --name "$CONTAINER_NAME" \
    --publish "127.0.0.1:${PORT}:${PORT}" \
    --volume "${SCRIPT_DIR}:/srv:ro" \
    --workdir /srv \
    python:3-alpine \
    python3 -m http.server "$PORT" \
    > /dev/null

  # Wait up to 5 s for the server to accept connections
  local attempts=0
  while (( attempts < 10 )); do
    if curl -sf "${URL}" &>/dev/null; then
      break
    fi
    sleep 0.5
    (( attempts++ ))
  done

  if is_running; then
    echo "  Server is up at ${URL}"
  else
    echo "  ERROR: Container started but server did not respond. Check logs:"
    echo "         bash server.sh logs"
    return 1
  fi
}

cmd_stop() {
  if ! container_exists; then
    echo "  Server is not running."
    return 0
  fi

  echo "  Stopping server..."
  $DOCKER stop "$CONTAINER_NAME" &>/dev/null
  $DOCKER rm   "$CONTAINER_NAME" &>/dev/null
  echo "  Server stopped."
}

cmd_restart() {
  cmd_stop
  cmd_start
}

cmd_logs() {
  if ! container_exists; then
    echo "  No container named '${CONTAINER_NAME}' — has the server been started?"
    return 1
  fi
  $DOCKER logs -f "$CONTAINER_NAME"
}

cmd_open() {
  if ! is_running; then
    echo "  Server is not running. Start it first:  bash server.sh start"
    return 1
  fi
  echo "  Opening ${URL}"
  open_browser
}

cmd_help() {
  grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \{0,1\}//'
}

# ── dispatch ───────────────────────────────────────────────────────────────────

case "${1:-}" in
  start)   cmd_start ;;
  stop)    cmd_stop ;;
  restart) cmd_restart ;;
  status)  cmd_status ;;
  logs)    cmd_logs ;;
  open)    cmd_open ;;
  doctor)  cmd_doctor ;;
  help|--help|-h) cmd_help ;;
  "")
    # Default: start (if not running) then open browser
    cmd_start && open_browser
    ;;
  *)
    echo "Unknown command: ${1}" >&2
    echo "Usage: bash server.sh [start|stop|restart|status|logs|open|doctor]" >&2
    exit 1
    ;;
esac
