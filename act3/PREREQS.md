# Act 3 Prerequisites — Local Model via Ollama

Before running `act3/run.sh`, complete the following steps **once** on your WSL machine.

## 1 — Install Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

The script downloads the Ollama binary from:

```
https://ollama.com/download/ollama-linux-amd64.tar.zst
```

**Corporate firewall note:** If you are behind a corporate proxy or Zscaler, the
download will fail with `curl: (22) The requested URL returned error: 404`. Whitelist
the exact URL above before running the install script.

To see the exact URL being fetched (useful for firewall tickets), save the script
and wrap `curl` calls with `set -x`:

```bash
curl -fsSL https://ollama.com/install.sh | tee /tmp/ollama.sh
# edit /tmp/ollama.sh: add  curl() { set -x; command curl "$@"; set +x; }
# after the available() function definition, then:
sh /tmp/ollama.sh
```

Verify the install:

```bash
ollama --version
```

## 2 — Start the Ollama service

### WSL2 + Docker networking requirement

Docker Desktop on WSL2 runs containers in a separate VM. Even with
`--network=host`, `localhost` inside the container resolves to the container's
own loopback — **not** the WSL host's loopback. Ollama's default bind address
(`127.0.0.1`) is therefore unreachable from the container.

**Ollama must be told to listen on all interfaces:**

```bash
OLLAMA_HOST=0.0.0.0 ollama serve
```

To avoid typing this every time, add it to your shell config:

```bash
echo 'export OLLAMA_HOST=0.0.0.0' >> ~/.bashrc
source ~/.bashrc
```

If you use systemd, override the service environment instead:

```bash
sudo systemctl edit ollama
```

Add:

```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
```

Then restart: `sudo systemctl restart ollama`

### Verify the service is up and reachable

```bash
curl -s http://localhost:11434
# expected: "Ollama is running"
```

On **WSL2 with systemd enabled**, the installer creates and starts a systemd
service automatically. If the service is not running (e.g. systemd is disabled),
start it manually in a background terminal:

```bash
OLLAMA_HOST=0.0.0.0 ollama serve
```

> **WSL2 + systemd tip:** To enable systemd in WSL2 if it is not already active,
> see [Microsoft's guide](https://learn.microsoft.com/en-us/windows/wsl/systemd).

## 3 — Pull the model

```bash
ollama pull qwen2.5-coder:7b
```

This downloads ~4.7 GB. Pull it once; subsequent runs use the local cache.

**No discrete GPU?** On CPU-only machines the 7B model is very slow. Pull the
1.5B model instead (~940 MB, roughly 4–5× faster):

```bash
ollama pull qwen2.5-coder:1.5b
```

Then change `"model"` in `act3/config/opencode/opencode.json` to
`"ollama/qwen2.5-coder:1.5b"`. Both models are already declared in the
`provider.ollama.models` block.

Verify the model is available:

```bash
ollama list
# qwen2.5-coder:7b and/or qwen2.5-coder:1.5b should appear
```

## 4 — OpenCode provider configuration

Pointing OpenCode at Ollama requires more than just `model: "ollama/..."` in the
config. The Ollama provider must be **explicitly declared** as a custom
OpenAI-compatible provider with its base URL and model list. The
`act3/config/opencode/opencode.json` already contains the required block:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/qwen2.5-coder:7b",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen2.5-coder:7b": {
          "name": "Qwen2.5-Coder 7B (local)"
        },
        "qwen2.5-coder:1.5b": {
          "name": "Qwen2.5-Coder 1.5B (local)"
        }
      }
    }
  }
}
```

`run.sh` passes this config via `OPENCODE_CONFIG`, which overrides the global
`~/.config/opencode/opencode.json`. Without the full `provider` block, OpenCode
ignores the `model` setting and falls back to the last-used cloud model.

## 5 — Run Act 3

```bash
bash act3/run.sh
```

OpenCode will start in your terminal, already configured to use
`qwen2.5-coder:7b` through Ollama. The status bar will show
**`Qwen2.5-Coder 7B (local) Ollama (local)`** confirming the local model is
active. Ask it anything — no tokens leave the machine.
