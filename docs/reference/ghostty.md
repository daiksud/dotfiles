# Ghostty

This is the reference for the Ghostty terminal emulator configuration files.

## File

`dotfiles/ghostty/config` → `~/.config/ghostty/config`

## Settings list

### Appearance

| Setting                      | Value                    | Description        |
| ---------------------------- | ------------------------ | ------------------ |
| `theme`                      | `TokyoNight Storm`       | Color scheme       |
| `font-family`                | `Moralerspace Neon HW`   | Font               |
| `font-size`                  | `13.5`                   | Font size          |
| `background-image`           | `hololive-en-advent.jpg` | Background image   |
| `background-image-fit`       | `cover`                  | Image fit method   |
| `background-image-opacity`   | `0.06`                   | Background opacity |
| `background-image-position`  | `center`                 | Image placement    |

### Window

| Setting                             | Value                     | Description                                         |
| ----------------------------------- | ------------------------- | --------------------------------------------------- |
| `fullscreen`                        | `non-native-visible-menu` | Fullscreen mode                                     |
| `macos-non-native-fullscreen`       | `visible-menu`            | macOS non-native fullscreen                         |
| `macos-titlebar-style`              | `hidden`                  | Hide the title bar                                  |
| `window-inherit-working-directory`  | `false`                   | Do not inherit the current directory in new windows |
| `window-padding-y`                  | `0`                       | Vertical padding                                    |

### Input

| Setting                    | Value  | Description                        |
| -------------------------- | ------ | ---------------------------------- |
| `macos-option-as-alt`      | `true` | Use the Option key as Alt          |
| `mouse-hide-while-typing`  | `true` | Hide the mouse cursor while typing |

### Disabled keybindings

To manage tabs and panes with tmux, all built-in Ghostty keybindings related to tabs and splits are disabled.

**Tab-related:**

- `⌘T` (new tab)
- `⌘⇧[` / `⌘⇧]` (switch tabs)
- `⌘1` through `⌘9` (jump to tab number)

**Split-related:**

- `⌘D` / `⌘⇧D` (split)
- `⌘⌥↑↓←→` (resize pane)
- `⌘⌃↑↓←→` (move pane)
- `⌘⇧Enter` (add pane)

## Background image

`dotfiles/ghostty/hololive-en-advent.jpg` is included in the configuration directory and placed via a symbolic link.
