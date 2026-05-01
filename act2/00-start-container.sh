#!/usr/bin/env bash
# ACT 2: Pre-authenticated OpenCode in Docker
#
# Prerequisite: the demo Docker image must be built first.
#   bash build.sh
#
# Launches opencode with credentials volume-mounted from the host — no login
# required inside the container.
#
# Directory layout on host:
#   act2/config/opencode/opencode.json  → /home/oc/.config/opencode/opencode.json
#   act2/local/                         → /home/oc/.local/
#     share/opencode/auth.json          →   share/opencode/auth.json
#                                           (state/ created here by opencode at runtime)
#
# Usage: bash act2/00-start-container.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib.sh"

require_image || exit 1

ensure_owned "${SCRIPT_DIR}/local"

$DOCKER run -it --rm "${USERNS_ARGS[@]}" \
  -v "${SCRIPT_DIR}/config/opencode:/home/oc/.config/opencode:ro" \
  -v "${SCRIPT_DIR}/local:/home/oc/.local" \
  -v "${TMUX_SOCKET}:${TMUX_SOCKET}" \
  "$DEMO_IMAGE"
