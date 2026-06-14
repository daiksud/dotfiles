# Zsh

This is the reference for Zsh shell configuration.

## Files

| Source           | Link destination | Contents                |
| ---------------- | ---------------- | ----------------------- |
| `dotfiles/zshrc` | `~/.zshrc`       | Main configuration file |
| `dotfiles/zsh/`  | `~/.zsh/`        | Custom plugin directory |

## `.zshrc` structure

`.zshrc` is processed in the following order:

1. **Auto-start tmux** — Connect to or create a tmux session
2. **Homebrew** — Set shell environment variables
3. **compinit** — Initialize the completion system (must come before sheldon)
4. **Emacs keybindings** — `bindkey -e`
5. **Sheldon** — Load plugins
6. **History settings** — History options
7. **Directory settings** — `auto_cd`, `auto_pushd`
8. **Completion style** — Case-insensitive and hyphen-insensitive matching
9. **EDITOR** — `nvim`
10. **Starship** — Initialize the prompt
11. **mise** — Enable runtime version management
12. **Custom functions** — Source all `~/.zsh/*.zsh`

## History settings

| Option                 | Description                                               |
| ---------------------- | --------------------------------------------------------- |
| `extended_history`     | Record timestamps and execution time                      |
| `hist_ignore_all_dups` | Remove duplicates completely                              |
| `hist_ignore_dups`     | Do not record the same command as the previous one        |
| `hist_ignore_space`    | Do not record commands that start with a space            |
| `hist_reduce_blanks`   | Remove extra spaces                                       |
| `hist_verify`          | Show history expansion without executing it immediately   |
| `share_history`        | Share history across sessions                             |

## Directory settings

| Option              | Description                                   |
| ------------------- | --------------------------------------------- |
| `auto_cd`           | Run `cd` with only a directory name           |
| `auto_pushd`        | Automatically run `pushd` on `cd`             |
| `pushd_ignore_dups` | Remove duplicate entries from the directory stack |

## Completion style

```zsh
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}'
```

Complete without distinguishing uppercase/lowercase and hyphen/underscore.
