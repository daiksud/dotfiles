# tmux

This is the configuration reference for the terminal multiplexer (tmux).

## File

`dotfiles/tmux.conf` → `~/.tmux.conf`

## Basic settings

| Setting            | Value           | Description                                 |
| ------------------ | --------------- | ------------------------------------------- |
| prefix             | `C-t`           | Prefix key (disables the default `C-b`)     |
| `default-terminal` | `xterm-ghostty` | Preserve Ghostty features even inside tmux  |
| `mode-keys`        | `vi`            | vi keybindings in copy mode                 |

## Keybindings

### Window and pane operations

| Key              | Action                                       |
| ---------------- | -------------------------------------------- |
| `prefix c`       | New window (inherits the current path)       |
| `prefix \`      | Horizontal split (inherits the current path) |
| `prefix -`       | Vertical split (inherits the current path)   |
| `prefix h/j/k/l` | Move between panes (vim-style)               |
| `prefix r`       | Reload configuration                         |

### Copy mode

| Key | Action                  |
| --- | ----------------------- |
| `v` | Start selection         |
| `y` | Copy and exit copy mode |

### Special keys

| Key           | Action                                     |
| ------------- | ------------------------------------------ |
| `Shift+Enter` | Send `\e[13;2u` (kitty keyboard protocol) |

## Plugins

Managed by TPM (Tmux Plugin Manager). Plugin directory: `~/.tmux/plugins/`

| Plugin                        | Description                  |
| ----------------------------- | ---------------------------- |
| `tmux-plugins/tpm`            | Plugin manager itself        |
| `tmux-plugins/tmux-sensible`  | Basic best-practice settings |
| `janoamaral/tokyo-night-tmux` | Tokyo Night theme            |

### Tokyo Night settings

| Key                       | Value   | Description   |
| ------------------------- | ------- | ------------- |
| `@tokyo-night-tmux_theme` | `storm` | Storm variant |

## Auto-start

In `.zshrc`, automatically connect to a tmux session:

```zsh
if [[ -z "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s main
fi
```

- `new-session -A -s main` — Attach if the `main` session exists; otherwise create it
- `exec` — Replace the shell with tmux (the terminal closes when tmux exits)

## Initializing TPM

Start TPM after prepending the Homebrew path:

```
run 'PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH" ~/.tmux/plugins/tpm/tpm'
```

This allows TPM's plugin scripts to use Homebrew's bash 5+.
