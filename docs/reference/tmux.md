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

When a shell starts, `.zshrc` connects it to a tmux session automatically.
Sessions are grouped by terminal application (read from `$TERM_PROGRAM`) so that
Ghostty, VS Code, and other apps stay in separate sessions. The implementation
lives in `dotfiles/zshrc`.

How it works:

- **App key** — `$TERM_PROGRAM` is lowercased and sanitized to `[a-z0-9-]`
  (`Ghostty` → `ghostty`, `vscode` → `vscode`, `Apple_Terminal` →
  `apple-terminal`). It falls back to `term` when `$TERM_PROGRAM` is unset.
- **Reattach a detached session** — if a session of the same application has no
  client attached, the shell reattaches to it instead of creating a new one.
  Sessions of other applications are never reused.
- **Otherwise start a new session** — when every same-app session is already
  attached (or none exist), a new session is created at the lowest free index,
  for example `ghostty-1`, then `ghostty-2`.
- **Replace the shell** — the shell process is replaced with tmux, so the
  terminal closes when tmux exits.

> [!NOTE]
> Each window gets its own independent session rather than mirroring a shared
> one. Detached sessions are recycled first, so closing and reopening a window
> reuses the freed session instead of leaving an orphan behind.

## Initializing TPM

TPM is initialized at the bottom of `tmux.conf`. The Homebrew paths
(`/opt/homebrew/bin`, `/opt/homebrew/sbin`) are prepended before TPM runs so that
its plugin scripts can find Homebrew's bash 5+ via `env(1)`. See
`dotfiles/tmux.conf` for the exact line.
