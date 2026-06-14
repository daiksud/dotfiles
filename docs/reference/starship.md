# Starship

This is the configuration reference for the cross-shell prompt (Starship).

## File

`dotfiles/starship.toml` → `~/.config/starship.toml`

## Prompt structure

A two-line prompt composed of Powerline-style gradient segments:

```
[░▒▓ ][directory][git_branch + git_status][languages][time]
[character]
```

### Segments and colors

| Segment                 | Background | Foreground | Contents                                 |
| ----------------------- | ---------- | ---------- | ---------------------------------------- |
| Icon                    | `#a3aed2`  | `#090c0c`  | Fixed icon ` `                           |
| directory               | `#769ff0`  | `#e3e5e5`  | Current directory (up to 3 levels)       |
| git_branch / git_status | `#394260`  | `#769ff0`  | Branch name + status                     |
| languages               | `#212736`  | `#769ff0`  | Node.js / Bun / Rust / Go / PHP versions |
| time                    | `#1d2230`  | `#a0a9cb`  | Current time (`HH:MM`)                   |

## Module settings

### directory

| Key                 | Value | Description                                   |
| ------------------- | ----- | --------------------------------------------- |
| `truncation_length` | `3`   | Maximum number of directory levels to display |
| `truncation_symbol` | `…/`  | Symbol used when truncated                    |

Special directory replacements:

| Directory | Display |
| --------- | ------- |
| Documents | `󰈙 `    |
| Downloads | ` `     |
| Music     | ` `     |
| Pictures  | ` `     |

### git_branch

Branch symbol: `` (Nerd Font)

### Language modules

Displays the version of detected languages. All use the same unified style:

| Module   | Symbol |
| -------- | ------ |
| `nodejs` | ``     |
| `bun`    | ``     |
| `rust`   | ``     |
| `golang` | ``     |
| `php`    | ``     |

### time

| Key           | Value   | Description    |
| ------------- | ------- | -------------- |
| `disabled`    | `false` | Enabled        |
| `time_format` | `%R`    | `HH:MM` format |
