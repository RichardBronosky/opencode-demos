#!/usr/bin/env bash
# demo.sh — narrator-mode walkthrough for the OpenCode in Docker demo.
#
# Usage:
#   bash demo.sh          # full walkthrough (all acts)
#   bash demo.sh build
#   bash demo.sh act1
#   bash demo.sh act2
#   bash demo.sh act3
#   bash demo.sh check    # prereq check only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

# ── helpers ──────────────────────────────────────────────────────────────────

bold()  { printf '\033[1m%s\033[0m' "$*"; }
dim()   { printf '\033[2m%s\033[0m' "$*"; }
head_() { echo; printf '\033[1;34m══ %s ══\033[0m\n' "$*"; echo; }
step()  { echo; printf '\033[1;33m▶ %s\033[0m\n' "$*"; }
info()  { printf '  %s\n' "$*"; }
cmd()   { echo; printf '  \033[1;32m$\033[0m %s\n' "$*"; echo; }
pause() { printf '\n  %s' "$(dim 'Press Enter to continue...')"; read -r _; echo; }
warn()  { printf '\033[1;31m⚠  %s\033[0m\n' "$*"; }

# ── prereq check ─────────────────────────────────────────────────────────────

check_prereqs() {
  head_ "Prerequisites"
  local ok=true

  if docker info &>/dev/null; then
    info "$(bold 'docker') ✓  ($(docker --version | head -1))"
  else
    warn "docker — not found or daemon not running"
    ok=false
  fi

  if command -v tmux &>/dev/null; then
    info "$(bold 'tmux')   ✓  ($(tmux -V))"
  else
    warn "tmux — not found (required for Act 2)"
    ok=false
  fi

  echo
  if [[ $ok == false ]]; then
    warn "One or more prerequisites are missing. Install them before continuing."
    return 1
  fi
  info "All prerequisites satisfied."
}

# ── next-step menu ────────────────────────────────────────────────────────────

# next_menu DEFAULT
# Prints a menu of all acts plus exit, with DEFAULT pre-selected on Enter.
# DEFAULT: build|act1|act2|act3|exit
next_menu() {
  local default="$1"

  local label_for_default
  case "$default" in
    build) label_for_default="Build" ;;
    act1)  label_for_default="Act 1" ;;
    act2)  label_for_default="Act 2" ;;
    act3)  label_for_default="Act 3" ;;
    exit)  label_for_default="Exit"  ;;
  esac

  echo
  info "[b] Build — Docker image (one-time prerequisite)"
  info "[1] Act 1 — Fresh auth → portable config"
  info "[2] Act 2 — Pre-authenticated + tmux socket forwarding"
  info "[3] Act 3 — Local model (no cloud, no credentials)"
  info "[q] Exit"
  echo
  printf '  What'"'"'s next? (Enter for %s): ' "$(bold "$label_for_default")"
  read -r choice
  [[ -z "$choice" ]] && choice="$default"

  case "$choice" in
    b|build) build_step ;;
    1|act1)  act1 ;;
    2|act2)  act2 ;;
    3|act3)  act3 ;;
    q|exit|quit) echo; info "Done."; echo ;;
    *) warn "Unknown choice '${choice}'. Exiting."; echo ;;
  esac
}

# ── build ─────────────────────────────────────────────────────────────────────

build_step() {
  head_ "Build — Docker image (one-time prerequisite)"
  info "All three acts run inside the same Docker image."
  info "Build it once here; Docker caches it for subsequent runs."
  pause

  step "Build the image"
  cmd "bash build.sh"
  info "Downloads OpenCode into a Ubuntu 24.04 image and sets it as the entrypoint."
  info "On a Zscaler network, the Zscaler root CA is injected automatically."
  pause

  info "Build complete. You can now run any act."
  next_menu "act1"
}

# ── act 1 ────────────────────────────────────────────────────────────────────

act1() {
  head_ "Act 1 — Fresh auth → portable config"
  info "Authenticate GitHub Copilot from scratch inside the container."
  info "The credentials are written back to the host via the volume mount,"
  info "producing a portable config bundle you can copy to any machine."
  pause

  step "Start the container"
  cmd "bash act1/run.sh"
  info "Checks that the Docker image exists, then launches OpenCode."
  info "If auth.json already exists from a prior run, the script will warn you"
  info "and offer to remove it — Act 1 only makes sense starting unauthenticated."
  info ""
  info "You will land on the OpenCode splash screen with no model yet selected."
  pause

  step "Authenticate with GitHub Copilot"
  info "Inside OpenCode:"
  info "  1. Type /models and press Enter (select from the slash-command menu)"
  info "  2. Type 'github' to filter, then Enter to select GitHub Copilot"
  info "  3. Select 'GitHub.com Public' and press Enter"
  info "  4. Visit https://github.com/login/device and enter the code shown"
  info "  5. Select Claude Sonnet 4.6 → Default"
  info ""
  info "See $(bold 'act1/DEMO.md') for a detailed step-by-step walkthrough."
  pause

  step "Verify and exit"
  info "Send a test prompt to confirm the model responds."
  info "Then press Escape and Ctrl+C (or q) to quit OpenCode."
  info ""
  info "The script prints the location of the portable credential bundle:"
  cmd "cp -r act1/config/opencode      ~/.config/opencode"
  cmd "cp -r act1/local/share/opencode ~/.local/share/opencode"
  pause

  info "Act 1 complete."
  next_menu "act2"
}

# ── act 2 ────────────────────────────────────────────────────────────────────

act2() {
  head_ "Act 2 — Pre-authenticated + tmux socket forwarding"
  info "OpenCode runs inside Docker with credentials volume-mounted from the host."
  info "No login flow required — it starts already authenticated."
  info ""
  info "The interesting part: the host's tmux socket is also mounted in, giving"
  info "the sandboxed agent a controlled escape hatch to discover, inspect, and"
  info "operate terminal panes on the host — all from inside the container."
  info ""
  info "We will prompt it to launch btop, handle the 'terminal too small' error,"
  info "resize the pane, and see btop succeed."
  pause

  step "Step 00 — Start OpenCode in the container"
  info "Run from $(bold 'any terminal') (tmux or plain):"
  cmd "bash act2/00-start-container.sh"
  info "Checks that the Docker image exists, then launches OpenCode with your"
  info "credentials and the host tmux socket both mounted in."
  info ""
  info "$(bold 'Do not paste the prompt yet') — that comes after Step 01."
  offer_terminal "run the OpenCode container from"
  pause

  step "Step 01 — Set up the tmux session with a collab pane"
  info "Run this from a $(bold 'new, plain terminal outside tmux')."
  info "This script creates the tmux session OpenCode will connect to."
  info "Running it from inside an existing tmux session would nest sessions."
  cmd "bash act2/01-from-new-terminal-launch-collab-tmux-session.sh"
  info "Creates the 'oc-demo-act2' session with two panes:"
  info "  • Top pane    — displays the prompt so you can copy it"
  info "  • Bottom pane ('collab') — where btop will run"
  info ""
  info "The collab pane is left in a dirty state on purpose (pwd typed, not sent)"
  info "to test whether OpenCode notices before sending any keys."
  offer_terminal "use as the plain terminal outside tmux"
  pause

  step "Paste the prompt"
  info "Copy the contents of act2/prompt.md and paste it as your first message"
  info "to OpenCode. Then watch it work."
  echo
  info "  $(dim "cat ${SCRIPT_DIR}/act2/prompt.md")"
  pause

  info "Act 2 complete."
  next_menu "act3"
}

# ── act 3 ────────────────────────────────────────────────────────────────────

act3() {
  head_ "Act 3 — Local model (no cloud, no credentials)"
  info "OpenCode runs inside the same demo container, but instead of GitHub Copilot"
  info "it uses a local Ollama model running on the WSL host."
  info "The container reaches Ollama over --network=host."
  info "No tokens leave the machine."
  pause

  step "Prerequisites (one-time)"
  info "Ollama must be installed and the model pulled before running this act."
  info "See $(bold 'act3/PREREQS.md') for the full setup. Quick version:"
  cmd "curl -fsSL https://ollama.com/install.sh | sh"
  cmd "ollama serve"
  cmd "ollama pull qwen2.5-coder:1.5b"
  pause

  step "Start the container"
  cmd "bash act3/run.sh"
  info "Checks that the Docker image, Ollama, and the model are all present."
  info "Launches OpenCode inside the container with --network=host so it can"
  info "reach Ollama at localhost:11434."
  pause

  step "Ask it something"
  info "Type any question into the OpenCode TUI."
  info "Inference runs entirely on your machine — watch the model respond locally."
  pause

  info "Act 3 complete."
  next_menu "exit"
}

# ── main ─────────────────────────────────────────────────────────────────────

case "${1:-all}" in
  check) check_prereqs ;;
  build) check_prereqs && build_step ;;
  act1)  check_prereqs && act1 ;;
  act2)  check_prereqs && act2 ;;
  act3)  check_prereqs && act3 ;;
  all)   check_prereqs && build_step ;;
  *)
    echo "Usage: bash demo.sh [check|build|act1|act2|act3]"
    exit 1
    ;;
esac
