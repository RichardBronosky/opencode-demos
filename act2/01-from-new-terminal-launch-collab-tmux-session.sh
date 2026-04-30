#!/usr/bin/env bash
# launch.sh — create the oc-demo-act2 tmux session with a collab pane,
# then show instructions for running opencode and feeding it the prompt.
#
# Usage: bash act2/launch.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION="oc-demo-act2"
YELLOW='\033[1;33m'
RED='\033[1;31m'
RESET='\033[0m'

source "${SCRIPT_DIR}/../lib.sh"

# Create session if it doesn't already exist
if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Session '$SESSION' already exists — attaching."
  tmux attach-session -t "$SESSION"
  exit 0
fi

# Top pane: cat the prompt then drop to an interactive shell
tmux new-session -d -s "$SESSION" "\
  printf '${YELLOW}';
  echo 'Copy the prompt between the pair of === lines below.';
  echo 'Paste it into the OpenCode session in the other terminal.';
  printf '${RESET}';
  printf '${RED}';
  echo '===';
  printf '${RESET}';
  echo;
  cat '${SCRIPT_DIR}/prompt.md';
  echo;
  printf '${RED}';
  echo '===';
  printf '${RESET}';
  exec bash
"

# Disable mouse only for this session so copy-paste works normally
tmux set -t "$SESSION" mouse off

# Bottom pane: collab (for the oc agent to operate), 8 rows tall
tmux split-window -v -l 12 -t "$SESSION"
tmux select-pane -T "collab" -t "${SESSION}:{end}"
COLLAB_PANE=$(tmux list-panes -t "$SESSION" -F "#{pane_id} #{pane_title}" | awk '/collab/{print $1}')
sleep 2
tmux send-keys -t "$COLLAB_PANE" 'ls -la' Enter
# The following creates a problem for our agent to detect. The command is typed, but without sending Enter.
tmux send-keys -t "$COLLAB_PANE" 'pwd'
# We want to test the agent's ability to handle a "dirty" shell.

# Focus top pane so instructions are front and center
tmux select-pane -t "${SESSION}:0.0"

tmux attach-session -t "$SESSION"
