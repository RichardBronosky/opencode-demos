# Act 2 — Pre-authenticated OpenCode in Docker

> "I already have GitHub Copilot credentials. How do I just bring them in?"

OpenCode runs inside a Docker container with your host credentials volume-mounted
in. No login flow inside the container — it starts authenticated and ready. This
act builds on Act 1: you use the credentials that Act 1 produced.

**Prerequisite:** the demo Docker image must be built before running this act.

```bash
bash build.sh
```

## Files

### `run.sh`

Checks that the demo image exists, then starts OpenCode inside the container.
Three volume mounts are passed to `docker run`:

| Mount                                          | Container path                        | Mode | Purpose                                      |
| ---------------------------------------------- | ------------------------------------- | ---- | -------------------------------------------- |
| `act2/config/opencode/`                        | `/home/oc/.config/opencode/`          | r/o  | Supplies `opencode.json` (model config)      |
| `act2/local/`                                  | `/home/oc/.local/`                    | r/w  | Supplies `auth.json`; receives runtime state |
| Host tmux socket (`/tmp/tmux-<uid>/default`)   | same path inside container            | r/w  | Lets OpenCode reach the host tmux server     |

The config mount is read-only (`:ro`) — OpenCode reads credentials but cannot
overwrite them. The `local/` mount is read-write so OpenCode can write its own
runtime state alongside `auth.json`.

```bash
bash act2/00-start-container.sh
```

### `01-from-new-terminal-launch-collab-tmux-session.sh`

Creates the `oc-demo-act2` tmux session that OpenCode will operate on. Run this
from a **plain terminal outside tmux** to avoid nesting sessions.

What it sets up:

- **Top pane** — displays `prompt.md` so you can copy it, then drops to a shell
- **Bottom pane** (named `collab`) — OpenCode's working pane, where `btop` will run

The collab pane is intentionally left in a "dirty" state: `ls -la` has run and
`pwd` is typed but not submitted. This tests whether OpenCode notices and handles
a shell that is not at a clean prompt.

```bash
bash act2/01-from-new-terminal-launch-collab-tmux-session.sh
```

### `config/opencode/opencode.json`

Tells OpenCode which model to use:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "github-copilot/claude-sonnet-4.6"
}
```

- `"$schema"` — enables editor validation and autocomplete against the OpenCode config schema
- `"model"` — `"github-copilot/claude-sonnet-4.6"` routes inference through the
  GitHub Copilot provider using Claude Sonnet 4.6; credentials are read from
  `local/share/opencode/auth.json`

### `prompt.md`

The cold-start prompt you paste into the OpenCode session after both scripts
have run. It instructs OpenCode to:

1. Find the tmux socket inside the container
2. Locate the `collab` pane in the `oc-demo-act2` session
3. Check whether the pane is at a clean prompt before acting
4. Launch `btop`, capture the output, and resize the pane if btop reports the
   terminal is too small

## Demo sequence

1. Run `bash build.sh` (once; cached after the first build)
2. Copy credentials from Act 1 into `act2/local/share/opencode/` (or use your own)
3. Run `bash act2/00-start-container.sh` — you land in an authenticated OpenCode session
4. In a separate plain terminal, run `bash act2/01-from-new-terminal-launch-collab-tmux-session.sh`
5. Switch back to the OpenCode terminal, paste the contents of `prompt.md`, and press Enter
6. Watch OpenCode find the pane, handle the dirty shell state, launch btop, and resize as needed
