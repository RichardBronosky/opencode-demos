# Agent Instructions — opencode-demos

## Before Every Commit

### 1. Verify that every referenced file exists

This repo has multiple markdown files and scripts that reference each other by
filename. These references get stale when files are renamed or removed.

Run this check:

```bash
# Extract .md and .sh file references from all tracked text files and verify each one.
# Anchors like #L42 should be stripped before checking.
git ls-files '*.md' '*.sh' \
  | xargs grep -oEh '\b(act[0-9]+/)?[A-Za-z0-9._-]+\.(md|sh)\b' \
  | sort -u \
  | while read -r ref; do
      ref_no_anchor="${ref%%#*}"
      [ -f "$ref_no_anchor" ] || echo "MISSING: $ref_no_anchor"
    done
```

If any file is reported MISSING, find every place it is referenced and update
the reference to the correct filename. Common past mistakes:

- `FLOW.md` renamed to `DEMO.md` but references left behind
- Act scripts renumbered but old filenames kept in prose

### 2. Verify act labels are consistent across files

Each act has a short label (e.g. "Act 2 — Pre-authenticated + tmux socket
forwarding"). That label appears in several places that must stay in sync:

| Location | What to check |
|---|---|
| `README.md` — walkthroughs table | The `Act N — …` cell text |
| `README.md` — section heading | The `## Act N — …` heading |
| `demo.sh` — `next_menu` info lines | The `[N] Act N — …` menu text |
| `demo.sh` — `head_` call | The `head_ "Act N — …"` string |
| `actN/README.md` — top heading | The `# Act N — …` heading |

To check: grep for each act's label pattern and confirm the wording matches.

```bash
for n in 1 2 3; do
  echo "=== Act $n labels ==="
  grep -n "Act ${n}[ —]" README.md demo.sh act${n}/README.md
  echo
done
```

The labels don't need to be character-for-character identical everywhere (the
menu line is shorter, the section heading is longer), but they must describe the
same concept. If one says "Pre-authenticated" and another says "Fresh auth" for
the same act, that's a bug.

### 3. Verify act ordering

The acts must appear in order (1, 2, 3) everywhere:

- `README.md` — the walkthroughs table rows and the `## Act N` sections
- `demo.sh` — the `next_menu` default chain must be: build → act1 → act2 → act3 → exit
- `demo.sh` — the menu items `[1]`, `[2]`, `[3]` must match the act numbers

```bash
# Check next_menu chain in demo.sh
grep -n 'next_menu' demo.sh
# Expected order of defaults: "act1", "act2", "act3", "exit"
```

### 4. Verify file-tree code blocks match disk

`README.md` contains code blocks showing directory trees for each act, like:

```
act1/
├── config/opencode/opencode.json
├── DEMO.md
└── run.sh
```

Compare these against the actual files:

```bash
for n in 1 2 3; do
  echo "=== act${n}/ on disk ==="
  find "act${n}" -type f | sort
  echo
done
```

If a file exists on disk but not in the tree block (or vice versa), update the
tree block to match disk. Disk is the source of truth.

### 5. Verify volume mount paths in prose match scripts

The `actN/README.md` files and `README.md` describe volume mounts in tables and
prose. The actual mounts are in the `docker run` commands in the `.sh` scripts.

For each act, open its run script and confirm:

- Every `-v` mount in the script is documented in the corresponding README
- The container paths (e.g. `/home/oc/.config/opencode/`) match between script
  and docs
- The `:ro` / read-write mode is correctly described

```bash
for script in act*/run.sh act*/00-start-container.sh; do
  [ -f "$script" ] || continue
  echo "=== $script ==="
  grep -- '-v ' "$script"
  echo
done
```

### 6. Scan for credentials

These files must never be committed:

| File | Reason |
|---|---|
| `act1/local/share/opencode/auth.json` | GitHub Copilot OAuth token |
| `act2/local/share/opencode/auth.json` | GitHub Copilot OAuth token |
| `zscaler-root-ca.crt` | Corporate CA certificate |

Before committing:

```bash
git diff --cached --name-only | grep -iE '(auth\.json|zscaler.*\.crt|\.pem)' && echo "STOP: credential file staged"
git diff --cached | grep -iE '(auth_token|access_token|client_secret|password|Bearer |ghp_|gho_|ghs_)' && echo "STOP: credential pattern found"
```

If any match is found, **stop and report to the user** — do not commit.
