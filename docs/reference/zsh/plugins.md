# Zsh Custom Plugins

This is the detailed reference for the custom plugins placed in `dotfiles/zsh/`.

## List

| File                              | Alias | Keybinding | Description                                              |
| --------------------------------- | ----- | ---------- | -------------------------------------------------------- |
| `gh-config-dir.zsh`               | —     | —          | Automatically configure Git identity and `GH_CONFIG_DIR` |
| `go-to-ghq-repository.zsh`        | `ggr` | `C-]`      | Select a repository and `cd` into it                     |
| `edit-ghq-repository.zsh`         | `egr` | —          | Select a repository and open it in `nvim`                |
| `edit-selected-file.zsh`          | `esf` | —          | Select a file and open it in `nvim`                      |
| `fzf-select-history.zsh`          | —     | `C-r`      | Search history with fzf                                  |
| `browse-github-notifications.zsh` | `bgn` | —          | Browse GitHub notifications                              |
| `open-lazygit.zsh`                | `olg` | —          | Launch lazygit                                           |
| `run-selected-command.zsh`        | —     | —          | Command execution utility                                |
| `history-substring-search.zsh`    | —     | `↑` / `↓`  | Substring history search                                 |
| `zshaddhistory.zsh`               | —     | —          | Exclude failed commands from history                     |

---

## gh-config-dir.zsh

The most important plugin, which automatically configures GitHub account information and the SSH signing key for each repository.

### Behavior

Runs automatically on every `cd` via the `chpwd` hook:

1. Check whether the current directory is inside a Git repository
2. Create `.git/gh/` and set it in `GH_CONFIG_DIR` (isolates `gh` authentication)
3. Only for GitHub origins, perform the following identity sync:
   - If local `user.name` / `user.email` are not set, fetch them with `gh api` and set them
   - Set `~/.ssh/<login>.pub` as `user.signingkey`
   - Update `~/.ssh/allowed_signers`

### Functions provided

| Function                    | Description                                                 |
| --------------------------- | ----------------------------------------------------------- |
| `is_github_origin_repo`     | Determine whether `origin` is `github.com`                 |
| `resolve_gh_identity`       | Get login name, name, and email from `gh api`              |
| `sync_signing_key_from_gh`  | Set the SSH signing key and `allowed_signers`              |
| `sync_git_identity_from_gh` | Sync `user.name`, `user.email`, and the signing key together |
| `set_gh_config_dir`         | Set `GH_CONFIG_DIR` and call identity sync                 |

For details, see [Automatic Git identity switching](../../guides/04-git-identity.md).

---

## go-to-ghq-repository.zsh

Get a repository list with `gh q list`, select one with fzf, and `cd` into it.

### Behavior

1. Get a list of local repository paths with `gh q list`
2. Display them after removing the `github.com` prefix
3. `cd` into the path selected with fzf

### Keybinding

- `C-]` — Invoke as a ZLE widget

### Alias

- `ggr`

---

## edit-ghq-repository.zsh

Select a repository with `gh q nvim` and open it in Neovim.

### Behavior

Runs `gh q nvim` via `run-selected-command`.

### Alias

- `egr`

---

## edit-selected-file.zsh

Select a file with fzf and open it in Neovim.

### Behavior

1. Select a file with `fzf` (the source list comes from `$FZF_DEFAULT_COMMAND` or fzf's default)
2. Run `nvim <file>` via `run-selected-command`

### Alias

- `esf`

---

## fzf-select-history.zsh

Interactive history search using fzf.

### Behavior

1. Get the full history in newest-first order with `history -n -r 1`
2. Pass the current command line (`$LBUFFER`) to fzf as the query
3. Set the selected history entry onto the command line

### Keybinding

- `C-r` — Invoke as a ZLE widget

---

## browse-github-notifications.zsh

List unread GitHub notifications (Issues / PRs), then select one and open its details.

### Behavior

1. Get unread notifications with `gh api notifications` (all pages)
2. Filter only Issues / PRs and display them as a table (`repository#number / title / reason`)
3. Select one with fzf, then run `gh pr view` or `gh issue view`

### Dependencies

`gh`, `jq`, `fzf`, `column`

### Alias

- `bgn`

---

## open-lazygit.zsh

Launch lazygit and, on exit, synchronize the current directory with the location moved to inside lazygit.

### Behavior

1. Set `LAZYGIT_NEW_DIR_FILE` and launch lazygit
2. After lazygit exits, `cd` into the directory written to the file

### Alias

- `olg`

---

## run-selected-command.zsh

A utility function called by other plugins.

### Behavior

- ZLE context (`$WIDGET` is set): Put the command in the buffer and call `accept-line`
- Normal context: Add it to history, then execute it directly

### Interface

```zsh
run-selected-command "command_line_string" cmd arg1 arg2 ...
```

---

## history-substring-search.zsh

Keybinding settings for the `zsh-history-substring-search` plugin.

### Keybindings

| Key          | Action                                                     |
| ------------ | ---------------------------------------------------------- |
| `↑` (`^[[A`) | Search backward through history using the text being typed |
| `↓` (`^[[B`) | Search forward through history using the text being typed  |

---

## zshaddhistory.zsh

Skip recording a command in history if the immediately previous command failed (exit code ≠ 0).

### Behavior

Define the `zshaddhistory` hook function and return `false` when `$?` is not 0 (= do not add to history).
