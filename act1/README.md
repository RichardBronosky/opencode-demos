# Act 1 — Fresh Auth → Portable Config

> "I want to authenticate from scratch and end up with a config I can carry anywhere."

OpenCode runs inside a Docker container with no pre-existing credentials. You
complete the GitHub Copilot device-flow login inside the container, and
`auth.json` is written back to the host through the volume mount. The result is
a portable credential bundle you can copy to any machine.

**Prerequisite:** the demo Docker image must be built before running this act.

```bash
bash build.sh
```

## Files

### `run.sh`

Checks that the demo image exists, then starts OpenCode inside the container.
Two volume mounts are passed to `docker run`:

| Mount                   | Container path                   | Mode | Purpose                                            |
| ----------------------- | -------------------------------- | ---- | -------------------------------------------------- |
| `act1/config/opencode/` | `/home/oc/.config/opencode/`     | r/w  | Supplies `opencode.json`; r/w so OpenCode can persist state |
| `act1/local/`           | `/home/oc/.local/`               | r/w  | Empty at start; `auth.json` is written here after login |

The config mount is read-write — OpenCode needs to persist the auth token it
receives from GitHub into the `local/` tree.

After the container exits, `run.sh` prints the contents of
`act1/local/share/opencode/` and shows copy commands to install the credentials
on any machine.

```bash
bash act1/run.sh
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
- `"model"` — sets the target model; OpenCode will prompt you to authenticate
  with GitHub Copilot when it starts because no `auth.json` is present yet

### `FLOW.md`

Step-by-step walkthrough of the interactive auth flow inside the container:
opening the model selector, filtering to GitHub Copilot, completing the
device-flow code entry, and selecting the model variant. Refer to this during
the live demo.

## Demo sequence

1. Run `bash build.sh` (once; cached after the first build)
2. Run `bash act1/run.sh` — OpenCode starts with no credentials
3. Follow the steps in `FLOW.md` to authenticate through the GitHub device flow
4. Exit OpenCode — `run.sh` prints the credential files now present on the host
5. Optional: copy the resulting dirs to any machine for an instant authenticated install

## Result

After a successful run, `act1/local/share/opencode/auth.json` contains your
GitHub Copilot OAuth token. The two directories together form a self-contained,
portable OpenCode credential bundle:

```
act1/config/opencode/opencode.json   ← model preference
act1/local/share/opencode/auth.json  ← GitHub Copilot token
```
