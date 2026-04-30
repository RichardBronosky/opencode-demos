# Act 3 — Local Model (No Cloud, No Credentials)

> "No tokens leave this machine."

OpenCode runs inside the same demo Docker container as Acts 1 and 2, but instead
of GitHub Copilot it uses a local [Ollama](https://ollama.com) model running on
the WSL host. The container reaches Ollama over the host network — no cloud API,
no credentials, no internet required after the one-time model download.

**Prerequisite:** the demo Docker image must be built before running this act.

```bash
bash build.sh
```

Also requires Ollama to be running on the WSL host with the model pulled.
See [`PREREQS.md`](PREREQS.md) for the one-time Ollama setup.

## Files

### `run.sh`

Runs four preflight checks, then launches OpenCode inside the demo container:

| Check                                     | Failure message                                      |
| ----------------------------------------- | ---------------------------------------------------- |
| Demo image exists                         | `ERROR: Docker image '...' not found` → `bash build.sh` |
| Ollama is reachable at `localhost:11434`  | `ERROR: Ollama is not running on localhost:11434`    |
| `qwen2.5-coder:1.5b` is in `ollama list` | `ERROR: Model '...' is not pulled`                  |

All errors print a remediation hint and point to the relevant doc.

`docker run` is called with `--network=host` so the container shares the WSL
host's network namespace. This lets OpenCode inside the container reach Ollama
at `localhost:11434` without any extra routing or port mapping.

```bash
bash act3/run.sh
```

### `config/opencode/opencode.json`

Configures the Ollama provider and selects the local model:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/qwen2.5-coder:1.5b",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen2.5-coder:7b":   { "name": "Qwen2.5-Coder 7B (local)"  },
        "qwen2.5-coder:1.5b": { "name": "Qwen2.5-Coder 1.5B (local)" }
      }
    }
  }
}
```

- `"model"` — sets the active model to `qwen2.5-coder:1.5b` via the `ollama` provider
- `"provider.ollama"` — registers Ollama as a custom provider using the
  OpenAI-compatible SDK (`@ai-sdk/openai-compatible`); `baseURL` points at the
  local Ollama REST API (reachable because `run.sh` uses `--network=host`)
- `"models"` — declares the models OpenCode should show in the model picker;
  both the 1.5B and 7B variants are listed so you can switch during the demo

The config is mounted read-only into the container (`run.sh` passes `:ro`),
so the demo config never modifies your files.

### `PREREQS.md`

One-time setup guide: installing Ollama in WSL, starting the service, pulling
the model, and verifying everything is ready before running `run.sh`.

## Demo sequence

1. Run `bash build.sh` (once; cached after the first build)
2. Complete the one-time Ollama setup in `PREREQS.md` (if not already done)
3. Run `bash act3/run.sh`
4. Ask OpenCode anything in the TUI — inference runs entirely on your machine
