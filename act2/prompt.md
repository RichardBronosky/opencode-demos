You are running inside a Docker container. You have access to the host's tmux
server via a socket mounted at the same path it has on the host. Find the socket:

```bash
ls /tmp/tmux-*/default
```

Use that path for all tmux commands, e.g. `tmux -S <socket>`.

Find the collab pane:

```bash
tmux -S <socket> list-panes -t oc-demo-act2 -F "#{pane_id} #{pane_title}"
```

The pane titled `collab` is your working pane. Capture its current state:

```bash
tmux -S <socket> capture-pane -p -t <collab-pane-id> | tail -8
```

If the last line shows a clean bash prompt (e.g. `user@host:...$`), run btop:

```bash
tmux -S <socket> send-keys -t <collab-pane-id> 'btop' Enter
```

If the pane is NOT at a clean prompt, just report the tail-8 output to me and
do not send any keys.

If you run btop, capture the pane, comprehend it, and resize the pane if btop needs you to.
