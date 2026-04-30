# Act 2 — Demo Walkthrough

> Pre-authenticated OpenCode + tmux collab pane + btop

Visual, step-by-step walkthrough for Act 2 with screenshots taken during a real
run. Use it alongside the live demo or as a rehearsal guide.

---

## Before you start

- The Docker image must be built: `bash build.sh`
- `act2/local/share/opencode/auth.json` must exist — copy it from Act 1:
  ```bash
  cp act1/local/share/opencode/auth.json act2/local/share/opencode/auth.json
  ```
- `tmux` must be installed on the host

---

## Step 1 — Start the OpenCode container

Run from **any terminal** (tmux or plain):

```bash
bash act2/00-start-container.sh
```

![Terminal: bash act2/00-start-container.sh — container starts, OpenCode launches](../assets/a2-01-start-container.png)

The script mounts credentials and the host tmux socket into the container.
OpenCode starts immediately — no login flow required. The status bar shows
`Claude Sonnet 4.6 GitHub Copilot`.

---

## Step 2 — Set up the tmux collab session

Run from a **plain terminal outside tmux** (not from inside an existing tmux
session — this script creates the session):

```bash
bash act2/01-from-new-terminal-launch-collab-tmux-session.sh
```

![New terminal: script runs, tmux session oc-demo-act2 created](../assets/a2-02-launch-collab-session.png)

The `oc-demo-act2` session opens with two panes:

- **Top pane** — shows the prompt text to copy and paste into OpenCode
- **Bottom pane** (`collab`) — OpenCode's working pane, left intentionally dirty
  (`pwd` typed but not submitted)

![tmux session showing top instruction pane and bottom collab pane](../assets/a2-03-tmux-session-layout.png)

---

## Step 3 — Paste the prompt into OpenCode

Switch to the terminal running OpenCode. Copy the text between the `===` markers
shown in the top tmux pane and paste it as your first message.

![OpenCode with prompt pasted — ready to submit](../assets/a2-04-prompt-pasted.png)

Press **Enter** to submit.

---

## Step 4 — OpenCode inspects the collab pane

OpenCode uses the mounted tmux socket to list panes in the `oc-demo-act2`
session and finds the `collab` pane. It captures the pane state and detects
that the shell is **not at a clean prompt** (`pwd` is typed but unsent).

![OpenCode tool output — capture-pane shows dirty shell state](../assets/a2-05-dirty-pane-detected.png)

OpenCode reports the dirty state back to you without sending any keys — exactly
as instructed.

---

## Step 5 — Clear the pane and launch btop

After you acknowledge, OpenCode clears the pending input and runs `btop` in the
collab pane.

![collab pane: btop launches but terminal too small error shown](../assets/a2-06-btop-too-small.png)

`btop` exits immediately with a **"terminal too small"** error — the collab pane
is only 12 rows tall.

---

## Step 6 — OpenCode resizes the pane and relaunches

OpenCode captures the error, resizes the collab pane to give `btop` enough
vertical space, and relaunches it.

![OpenCode tool calls: resize-pane then send-keys btop](../assets/a2-07-resize-and-relaunch.png)

`btop` now starts successfully and fills the enlarged pane.

![collab pane: btop running, CPU/memory graphs visible](../assets/a2-08-btop-running.png)

---

## Step 7 — Exit

Press `q` in the collab pane to quit `btop`. Press `Escape` then `q` in the
OpenCode session to exit.

![Terminal after OpenCode exits](../assets/a2-09-exit.png)

---

[← Act 1](../act1/DEMO.md) · **Act 2** · [Act 3 →](../act3/DEMO.md)
