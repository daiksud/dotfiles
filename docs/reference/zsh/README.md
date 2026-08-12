# Zsh

This is the reference for Zsh shell configuration.

## Files

| Source | Link destination | Contents |
| ---------------- | ---------------- | ----------------------- |
| `dotfiles/zshrc` | `~/.zshrc` | Main configuration file |
| `dotfiles/zsh/` | `~/.zsh/` | Custom plugin directory |

## `.zshrc` structure

`.zshrc` is processed in the following order:

1. **Homebrew** — Set shell environment variables
2. **compinit** — Initialize the completion system (must come before sheldon)
3. **Emacs keybindings** — `bindkey -e`
4. **Sheldon** — Load plugins
5. **History settings** — History options
6. **Directory settings** — `auto_cd`, `auto_pushd`
7. **Completion style** — Case-insensitive and hyphen-insensitive matching
8. **EDITOR** — `nvim`
9. **Starship** — Initialize the prompt
10. **mise** — Enable runtime version management
11. **Custom functions** — Source all `~/.zsh/*.zsh`

## Custom plugins

`.zshrc` sources every `~/.zsh/*.zsh` file in glob order. `dotfiles/zsh/`
currently provides:

| File | Purpose |
| --- | --- |
| `browse-github-notifications.zsh` | Browse GitHub notifications |
| `edit-repository.zsh` | Select a gh-qw checkout and open it in `nvim` |
| `edit-selected-file.zsh` | Select a file and open it in `nvim` |
| `fzf-select-history.zsh` | Search history with fzf |
| `gh-account.zsh` | Select the GitHub account and Git identity with owner defaults |
| `go-to-repository.zsh` | Select a gh-qw checkout and `cd` into it |
| `history-substring-search.zsh` | Substring history search keybindings |
| `open-lazygit.zsh` | Launch lazygit and follow its directory changes |
| `repository-select.zsh` | Shared fzf selector for gh-qw managed checkouts |
| `run-selected-command.zsh` | Command execution utility used by other plugins |
| `zshaddhistory.zsh` | Exclude failed commands from history |

See [Zsh custom plugins](./plugins.md) for each plugin's behavior, alias, and
keybinding.

## History settings

| Option | Description |
| ---------------------- | ------------------------------------------------------- |
| `extended_history` | Record timestamps and execution time |
| `hist_ignore_all_dups` | Remove duplicates completely |
| `hist_ignore_dups` | Do not record the same command as the previous one |
| `hist_ignore_space` | Do not record commands that start with a space |
| `hist_reduce_blanks` | Remove extra spaces |
| `hist_verify` | Show history expansion without executing it immediately |
| `share_history` | Share history across sessions |

## Directory settings

| Option | Description |
| ------------------- | ------------------------------------------------- |
| `auto_cd` | Run `cd` with only a directory name |
| `auto_pushd` | Automatically run `pushd` on `cd` |
| `pushd_ignore_dups` | Remove duplicate entries from the directory stack |

## Completion style

Completion matches without distinguishing uppercase/lowercase or
hyphen/underscore. This is configured with a `zstyle` `matcher-list` rule in
`dotfiles/zshrc`.
