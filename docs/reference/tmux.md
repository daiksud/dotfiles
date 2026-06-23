# tmux

This is the configuration reference for the terminal multiplexer (tmux).

## File

`dotfiles/tmux.conf` → `~/.tmux.conf`

## Basic settings

| Setting            | Value           | Description                                |
| ------------------ | --------------- | ------------------------------------------ |
| prefix             | `C-t`           | Prefix key (disables the default `C-b`)    |
| `default-terminal` | `xterm-ghostty` | Preserve Ghostty features even inside tmux |
| `mode-keys`        | `vi`            | vi keybindings in copy mode                |

## Keybindings

### Window and pane operations

| Key              | Action                                       |
| ---------------- | -------------------------------------------- |
| `prefix c`       | New window (inherits the current path)       |
| `prefix \`       | Horizontal split (inherits the current path) |
| `prefix -`       | Vertical split (inherits the current path)   |
| `prefix h/j/k/l` | Move between panes (vim-style)               |
| `prefix r`       | Reload configuration                         |

### Copy mode

| Key | Action                  |
| --- | ----------------------- |
| `v` | Start selection         |
| `y` | Copy and exit copy mode |

### Special keys

| Key           | Action                                    |
| ------------- | ----------------------------------------- |
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

In `.zshrc`, automatically connect to a tmux session. Sessions are grouped by
terminal application (read from `$TERM_PROGRAM`) so that Ghostty, VS Code, and
other apps stay in separate sessions:

```zsh
if [[ -z "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
  () {
    local app="${TERM_PROGRAM:-term}"
    app="${app:l}"            # lowercase
    app="${app//[^a-z0-9]/-}" # sanitize to [a-z0-9-]
    local target
    target=$(tmux list-sessions -F '#{session_attached} #{session_name}' 2>/dev/null \
      | awk -v a="$app" '$1 == 0 && $2 ~ ("^" a "(-|$)") { print $2; exit }')
    if [[ -n "$target" ]]; then
      exec tmux attach-session -t "$target"
    fi
    local n=1
    while tmux has-session -t "${app}-${n}" 2>/dev/null; do
      (( n++ ))
    done
    exec tmux new-session -s "${app}-${n}"
  }
fi
```

How it works:

- **App key** — `$TERM_PROGRAM` is lowercased and sanitized to `[a-z0-9-]`
  (`Ghostty` → `ghostty`, `vscode` → `vscode`, `Apple_Terminal` →
  `apple-terminal`). It falls back to `term` when `$TERM_PROGRAM` is unset.
- **Reattach a detached session** — `tmux list-sessions` reports each session's
  attached client count. If a session named `<app>` or `<app>-<n>` has no client
  attached (`#{session_attached}` is `0`), the shell reattaches to it. Only
  sessions of the same application are considered.
- **Otherwise start a new session** — when every same-app session is already
  attached (or none exist), a new session is created at the lowest free index,
  for example `ghostty-1`, then `ghostty-2`.
- **Anonymous function `() { ... }`** — keeps the helper variables local without
  declaring `local` at file scope.
- **`exec`** — replaces the shell with tmux (the terminal closes when tmux exits).

> [!NOTE]
> Each window gets its own independent session rather than mirroring a shared
> one. Detached sessions are recycled first, so closing and reopening a window
> reuses the freed session instead of leaving an orphan behind.

## Initializing TPM

Start TPM after prepending the Homebrew path:

```
run 'PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH" ~/.tmux/plugins/tpm/tpm'
```

This allows TPM's plugin scripts to use Homebrew's bash 5+.
