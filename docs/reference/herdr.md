# herdr

This is the configuration reference for the terminal multiplexer (herdr).

## File

`dotfiles/herdr.toml` → `~/.config/herdr/config.toml`

Onboarding is skipped, the theme is set to Tokyo Night, and the prefix key is
remapped from herdr's default. The split-down keyboard shortcut is also
customized to preserve 70% of the height for the existing upper pane and use
30% for the new lower pane. Every other behavior — split-right, pane
navigation, and copy mode — uses herdr's built-in defaults. See
`dotfiles/herdr.toml` for the exact values.

## Model

| Level | Description |
| ----------- | --------------------------------------------------------------------- |
| Workspace | Top-level project or work context. Owns tabs and panes |
| Tab | A layout inside a workspace, addressable from the CLI and socket API |
| Pane | A real terminal process. Preserved across client detach |

## Basic settings

| Setting | Value | Description |
| -------------- | ------------- | ------------------------------------------------------- |
| Prefix | `ctrl+t` | Overridden from herdr's default `ctrl+b` (see below) |
| `theme.name` | `tokyo-night` | Built-in theme, no plugin required |
| `onboarding` | `false` | Skips first-run setup |

herdr's default prefix is `ctrl+b`, but this repository remaps it to
`ctrl+t`. `ctrl+b` is `backward-char` in the Emacs keybindings used elsewhere
(`bindkey -e` in `dotfiles/zshrc`, and insert-mode `<C-b>` in
`dotfiles/nvim/lua/config/keymaps.lua`), and a multiplexer prefix always wins
over the keys bound inside its panes. See
[ADR 0017](../development/99-adr/0017-herdr-prefix-ctrl-t.md) for the full
rationale.

## Keybindings

Except for split-down, every action below is bound to herdr's built-in default
key. `prefix` itself is remapped to `ctrl+t` (see
[Basic settings](#basic-settings) above), so read `prefix` in the tables below
as `ctrl+t`.

### Panes and tabs

| Key | Action |
| ----------------- | -------------------------------- |
| `prefix c` | New tab |
| `prefix v` | Split right |
| `prefix -` | Split down with the existing pane above at 70% and the new pane below at 30% |
| `prefix h/j/k/l` | Move between panes |
| `prefix z` | Zoom the focused pane |
| `prefix x` | Close pane |
| `prefix n` / `p` | Next / previous tab |
| `prefix q` | Detach, leave everything running |

`prefix -` replaces herdr's built-in split-down binding with a custom command.
After creating the 70:30 split, focus moves to the new lower pane. This ratio
applies only to the keyboard shortcut: splits from the menu and direct
`herdr pane split` commands retain herdr's default behavior unless the caller
supplies a ratio explicitly.

### Copy mode

Enter with `prefix [`.

| Key | Action |
| ----- | ------------------------- |
| `v` | Start selection |
| `y` | Copy and exit copy mode |
| `q` | Leave without copying |

Full navigation (`h/j/k/l`, `w/b/e`, `/` and `?` search) and the complete
keymap are documented at [herdr's keyboard reference](https://herdr.dev/docs/keyboard/).

Copy mode also binds `ctrl+b` / `ctrl+f` for page-up/page-down. herdr's
built-in default prefix is `ctrl+b` too, which would shadow page-up; since
this repository moves the prefix to `ctrl+t`, `ctrl+b` reaches copy mode's
page-up as documented.

## Server lifecycle

herdr runs as a background server plus one or more attached clients. The
server owns panes and process state, so panes and any agents inside them keep
running after a client detaches or a terminal window closes.

On macOS, `scripts/100-herdr.sh` keeps the server resident through a Homebrew
LaunchAgent. It checks the client/server compatibility and leaves a healthy
service alone, including when only the client and server version strings
differ. If a Homebrew upgrade left an incompatible server running, the script
stops the old service and default server, starts the current service, and
verifies the new server before reporting success. It performs the same handoff
when the server is compatible but its Homebrew service is unhealthy. Inherited
`HERDR_SOCKET_PATH` and `HERDR_SESSION` selectors are ignored so named and
custom sessions are not mistaken for the Homebrew-managed default session. The
script serializes its complete lifecycle decision so concurrent installers
cannot stop a server recovered by the other. After stopping a Homebrew job, it
rechecks both states before stopping a remaining server. A failed post-stop
status query triggers a best-effort reload of the job before setup fails.

Stopping a server terminates its panes. The setup therefore refuses a required
handoff when `HERDR_ENV=1`, before changing the Homebrew service. Save any
recoverable work, open a plain shell outside Herdr, and rerun `bash install.sh`.
If an interrupted installation already left the service in a failed state, run
this recovery sequence from that plain shell:

```bash
brew services stop herdr
herdr server stop
brew services start herdr
herdr status
```

Opening a Ghostty window attaches to the default session automatically through
`command` in `dotfiles/ghostty/config` (see
[Ghostty](./ghostty.md#startup-command)); other launch paths (VS Code,
Codespaces, SSH sessions started some other way) still start a plain shell.
Run `herdr` manually to attach from one of those, or `herdr --session <name>`
for a separate named session.

> [!WARNING]
> `herdr server stop` exits all processes in the server's panes. Do not run
> the recovery sequence while agents or other important commands are active.

## Environment variables

Panes started by herdr expose `HERDR_ENV=1`, which scripts can check to
detect that they are already running inside a herdr pane (herdr uses this
itself to block nested launches; `dotfiles/ghostty/herdr-launch.sh` checks it
for the same reason). Named or custom sessions can also select their server
through `HERDR_SESSION` or `HERDR_SOCKET_PATH`. Panes expose `HERDR_PANE_ID`,
`HERDR_TAB_ID`, and `HERDR_WORKSPACE_ID` to identify the current pane, tab, and
workspace.

## Constraints

| Item | Description |
| ------------ | -------------------------------------------------------------------------- |
| Pane `TERM` | Fixed to `xterm-256color` (`COLORTERM=truecolor`); not configurable |
| Status | Shown in herdr's sidebar, not a status bar |
| Theme variant | Only `tokyo-night` and its light sibling `tokyo-night-day` are built in |
