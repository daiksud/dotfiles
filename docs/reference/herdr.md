# herdr

This is the configuration reference for the terminal multiplexer (herdr).

## File

`dotfiles/herdr.toml` → `~/.config/herdr/config.toml`

Only two settings are pinned: onboarding is skipped, and the theme is set to
Tokyo Night. Every other behavior — the prefix key, pane splits, pane
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
| -------------- | ------------- | -------------------------------------- |
| Prefix | `ctrl+b` | herdr's default prefix key (unchanged) |
| `theme.name` | `tokyo-night` | Built-in theme, no plugin required |
| `onboarding` | `false` | Skips first-run setup |

## Keybindings

Every binding below is herdr's built-in default; none are configured by this
repository.

### Panes and tabs

| Key | Action |
| ----------------- | -------------------------------- |
| `prefix c` | New tab |
| `prefix v` | Split right |
| `prefix -` | Split down |
| `prefix h/j/k/l` | Move between panes |
| `prefix z` | Zoom the focused pane |
| `prefix x` | Close pane |
| `prefix n` / `p` | Next / previous tab |
| `prefix q` | Detach, leave everything running |

### Copy mode

Enter with `prefix [`.

| Key | Action |
| ----- | ------------------------- |
| `v` | Start selection |
| `y` | Copy and exit copy mode |
| `q` | Leave without copying |

Full navigation (`h/j/k/l`, `w/b/e`, `/` and `?` search) and the complete
keymap are documented at [herdr's keyboard reference](https://herdr.dev/docs/keyboard/).

## Server lifecycle

herdr runs as a background server plus one or more attached clients. The
server owns panes and process state, so panes and any agents inside them keep
running after a client detaches or a terminal window closes.

`scripts/100-herdr.sh` keeps the server resident via `brew services start
herdr` on macOS. Opening a terminal does not attach to herdr automatically;
run `herdr` to attach to the default session, or `herdr --session <name>` for
a separate named session.

## Environment variables

Panes started by herdr expose `HERDR_PANE_ID`, `HERDR_TAB_ID`, and
`HERDR_WORKSPACE_ID`, which scripts can use to detect that they are running
inside herdr.

## Constraints

| Item | Description |
| ------------ | -------------------------------------------------------------------------- |
| Pane `TERM` | Fixed to `xterm-256color` (`COLORTERM=truecolor`); not configurable |
| Status | Shown in herdr's sidebar, not a status bar |
| Theme variant | Only `tokyo-night` and its light sibling `tokyo-night-day` are built in |
