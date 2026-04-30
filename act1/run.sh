#!/usr/bin/env bash
# ACT 1: Fresh GitHub Copilot auth inside Docker → portable config dir
#
# Prerequisite: the demo Docker image must be built first.
#   bash build.sh
#
# Launches opencode with no pre-existing credentials.
# After completing the GitHub Copilot device-flow login inside the container,
# auth.json is written back to the host via the volume mount.
#
# Directory layout on host (before running):
#   act1/config/opencode/opencode.json  → /home/oc/.config/opencode/opencode.json (pre-loaded)
#   act1/local/                         → /home/oc/.local/ (fills in after login)
#     share/opencode/auth.json          →   written here after Copilot auth
#
# Usage: bash act1/run.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib.sh"

require_image || exit 1

# Ensure .local tree exists and is owned by current user
ensure_owned "${SCRIPT_DIR}/local"

# Act 1 demonstrates the fresh-auth flow. If auth.json already exists from a
# prior run, OpenCode will start authenticated and skip the login flow entirely
# — defeating the point of the demo. Prompt to remove it.
AUTH_JSON="${SCRIPT_DIR}/local/share/opencode/auth.json"
if [[ -f "$AUTH_JSON" ]]; then
  echo "WARNING: auth.json already exists from a previous run:"
  echo "  ${AUTH_JSON}"
  echo ""
  echo "Act 1 demos the fresh-auth flow. If you continue with this file present,"
  echo "OpenCode will start already authenticated and skip the login step."
  echo ""
  printf "Remove it and start fresh? [y/N] "
  read -r reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    rm -f "$AUTH_JSON"
    echo "Removed. Starting with no credentials."
  else
    echo "Keeping existing credentials. The auth flow will not be triggered."
  fi
  echo ""
fi

docker run -it --rm \
  -v "${SCRIPT_DIR}/config/opencode:/home/oc/.config/opencode" \
  -v "${SCRIPT_DIR}/local:/home/oc/.local" \
  "$DEMO_IMAGE"

echo ""
echo "=== Portable config after auth ==="
ls -la "${SCRIPT_DIR}/local/share/opencode/"
echo ""
echo "To reuse these credentials anywhere:"
echo "  cp -r ${SCRIPT_DIR}/config/opencode       ~/.config/opencode"
echo "  cp -r ${SCRIPT_DIR}/local/share/opencode  ~/.local/share/opencode"
