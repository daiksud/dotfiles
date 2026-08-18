# Ghostty

This is the reference for the Ghostty terminal emulator configuration files.

## File

`dotfiles/ghostty/config` → `~/.config/ghostty/config`

## Settings list

### Appearance

| Setting | Value | Description |
| --------------------------- | ------------------------ | ------------------ |
| `theme` | `TokyoNight Storm` | Color scheme |
| `font-family` | `Moralerspace Neon HW` | Font |
| `font-size` | `13.5` | Font size |
| `background-image` | `hololive-en-advent.jpg` | Background image |
| `background-image-fit` | `cover` | Image fit method |
| `background-image-opacity` | `0.06` | Background opacity |
| `background-image-position` | `center` | Image placement |

### Window

| Setting | Value | Description |
| ---------------------------------- | ------------------------- | --------------------------------------------------- |
| `fullscreen` | `non-native-visible-menu` | Fullscreen mode |
| `macos-non-native-fullscreen` | `visible-menu` | macOS non-native fullscreen |
| `macos-titlebar-style` | `hidden` | Hide the title bar |
| `window-inherit-working-directory` | `false` | Do not inherit the current directory in new windows |
| `window-padding-y` | `0` | Vertical padding |

### Input

| Setting | Value | Description |
| ------------------------- | ------ | ---------------------------------- |
| `macos-option-as-alt` | `true` | Use the Option key as Alt |
| `mouse-hide-while-typing` | `true` | Hide the mouse cursor while typing |

### Startup command

| Setting | Value | Description |
| --------- | ---------------------------------------- | -------------------------------------------------------------- |
| `command` | `shell:~/.config/ghostty/herdr-launch.sh` | Runs `dotfiles/ghostty/herdr-launch.sh` for every new surface |

Ghostty's GUI process does not inherit a login shell's `PATH`, so it cannot
resolve a bare `herdr` command. `dotfiles/ghostty/herdr-launch.sh` adds the
common Homebrew bin directories to `PATH` and then execs `herdr`, so every new
window or tab attaches to herdr's persistent default session automatically
(see [herdr](./herdr.md) for session and pane lifecycle). Because the wrapper
replaces itself with `herdr` via `exec`, detaching (`prefix+q`) or otherwise
exiting herdr closes that surface, while the server and its panes keep
running in the background.

The wrapper falls back to a login shell (`$SHELL -l`) instead of `herdr` when
herdr is not installed, or when it is already running inside a herdr pane
(`HERDR_ENV=1`) to avoid herdr's nested-launch guard. To open a plain shell
deliberately instead of attaching to herdr, run `ghostty -e zsh` (or another
shell); the `-e` flag overrides `command` for that one surface.

### Disabled keybindings

To manage tabs and panes with herdr, all built-in Ghostty keybindings related to tabs and splits are disabled.

**Tab-related:**

- `⌘T` (new tab)
- `⌘⇧[` / `⌘⇧]` (switch tabs)
- `⌘1` through `⌘9` (jump to tab number)

**Split-related:**

- `⌘D` / `⌘⇧D` (split)
- `⌘⌥↑↓←→` (resize pane)
- `⌘⌃↑↓←→` (move pane)
- `⌘⇧Enter` (add pane)

### Emacs key remappings

The following terminal-level translations preserve the Emacs editing actions
used by zsh and Copilot CLI while avoiding conflicting application shortcuts.

| Chord | Ghostty output | zsh binding | Alternate |
| ---------------- | ---------------- | ---------------- | ------------------------------ |
| `ctrl+d` | `CSI 3~` (Delete) | `delete-char` | `ctrl+alt+d` sends EOF |
| `ctrl+e` | `CSI F` (End) | `end-of-line` | `ctrl+alt+e` sends raw `Ctrl+E` |

The `ctrl+d` mapping prevents Copilot CLI elicitation forms from treating
forward-delete as a destructive decline action (see
[ADR 0030](../development/99-adr/0030-ghostty-ctrl-d-delete-key.md)). The
`ctrl+e` mapping prevents the Plan Ready for Review dialog from treating
end-of-line as a summary/full-plan toggle (see
[ADR 0031](../development/99-adr/0031-ghostty-ctrl-e-end-key.md)). Both
mappings apply to every program running in Ghostty.

## Reloading after configuration changes

Ghostty reads its configuration into the running application process. The
`command` setting applies to new windows, tabs, and other surfaces; it does not
replace the process already running in an existing surface. On macOS, closing
the last window normally leaves the Ghostty application alive, so reopening a
window can still use a configuration loaded before `install.sh` updated the
symbolic link.

After installing or updating this configuration while Ghostty is open:

1. Press `⌘⇧,` (Command+Shift+comma) to reload the configuration.
2. Open a new window or tab so the startup command is applied.
3. If the old behavior remains, quit Ghostty with `⌘Q` and launch it again.

The [Ghostty configuration guide](https://ghostty.org/docs/config#reloading-the-configuration) documents the reload action. Validate the file and inspect the effective command with:

```bash
ghostty +validate-config
ghostty +show-config | rg '^command = '
```

These commands start a separate Ghostty CLI process and verify the
configuration on disk; they do not prove that an already-running GUI process
has reloaded it. Always create a new surface after reloading before checking
the runtime environment.

Run the following from the newly created surface to distinguish a herdr client
from a plain shell:

```bash
printf 'HERDR_ENV=%s\n' "${HERDR_ENV:-<unset>}"
herdr status client
```

`HERDR_ENV=1` confirms that the process is inside a herdr-managed pane. A
missing value is expected for a deliberate `ghostty -e zsh` launch, but after a
normal Ghostty launch it indicates that the wrapper [fell back to the login
shell](https://github.com/daiksud/dotfiles/blob/main/dotfiles/ghostty/herdr-launch.sh) or that the running Ghostty
process has not loaded the current configuration.

## Background image

`dotfiles/ghostty/hololive-en-advent.jpg` is included in the configuration directory and placed via a symbolic link.
