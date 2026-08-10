# Zsh Custom Plugins

This is the detailed reference for the custom plugins placed in `dotfiles/zsh/`.

## List

| File | Alias | Keybinding | Description |
| --------------------------------- | ----- | ---------- | -------------------------------------------------------- |
| `gh-account.zsh` | `ghu` | — | Select the GitHub account and Git identity per repository |
| `repository-select.zsh` | — | — | Shared fzf selector for gh-qw managed checkouts |
| `go-to-repository.zsh` | `ggr` | `C-]` | Select a gh-qw checkout and `cd` into it |
| `edit-repository.zsh` | `egr` | — | Select a gh-qw checkout and open it in `nvim` |
| `edit-selected-file.zsh` | `esf` | — | Select a file and open it in `nvim` |
| `fzf-select-history.zsh` | — | `C-r` | Search history with fzf |
| `browse-github-notifications.zsh` | `bgn` | — | Browse GitHub notifications |
| `open-lazygit.zsh` | `olg` | — | Launch lazygit |
| `run-selected-command.zsh` | — | — | Command execution utility |
| `history-substring-search.zsh` | — | `↑` / `↓` | Substring history search |
| `zshaddhistory.zsh` | — | — | Exclude failed commands from history |

---

## gh-account.zsh

The most important plugin, which selects the GitHub account, Git identity, and
SSH signing key to use in each repository.

Every account stays in `gh`'s single user-level configuration. The central
mapping file `~/.config/gh/repos.json` (override with `GH_ACCOUNT_MAP_FILE`)
records which of those accounts each repository uses, keyed by the canonical
lowercase `<host>/<owner>/<repo>` identity of `origin`. The choice is applied
through `GH_TOKEN` and `GIT_CONFIG_*` environment variables so it never leaves
the current shell. `GH_CONFIG_DIR` is not used at all, and `gh auth switch` is
deliberately avoided because it would move the globally active account for
every terminal.

### Behavior

`gh-account-sync` is registered on the `chpwd` hook and runs on every `cd`:

1. Resolve the `<host>/<owner>/<repo>` identity of `origin`, and clear the
   injected environment when the directory is not a GitHub repository
2. Look the identity up in the mapping file, reusing the already applied
   account when it has not changed
3. Export `GH_TOKEN` for the stored account, and inject `user.name`,
   `user.email`, and — when `~/.ssh/<login>.pub` exists — `user.signingkey`
   through `GIT_CONFIG_COUNT` / `GIT_CONFIG_KEY_<n>` /
   `GIT_CONFIG_VALUE_<n>`, which take precedence over every configuration file
4. Prompt for an account with fzf when the repository is unmapped

The prompt appears only in an interactive shell: it is skipped inside a zle
widget, when stdin is not a terminal, and when `TERM` is `dumb`, so a
non-interactive shell never blocks on it.

`gh-account.zsh` deliberately never reads, sets, or clears
`COPILOT_GITHUB_TOKEN`. Copilot user selection belongs to the parent process.
See
[Automatic Git identity switching](../../guides/04-git-identity.md).

### Functions provided

| Function | Description |
| --------------------------- | ------------------------------------------------------------ |
| `gh-account-repo-id` | Normalize a remote URL into a `<host>/<owner>/<repo>` identity |
| `gh-account-map-get` | Read one field of a mapping entry |
| `gh-account-map-set` | Create or replace a mapping entry |
| `gh-account-map-unset` | Delete a mapping entry |
| `gh-account-logins` | List the logins stored in `gh`'s configuration for a host |
| `gh-account-token` | Print the stored token of a login |
| `gh-account-login` | Run `gh auth login` with a clean environment to add an account |
| `gh-account-select` | Choose (or re-choose) the account for the current repository; `--forget` removes the mapping |
| `gh-account-cleanup-local` | Remove the local identity settings written by the previous design |
| `gh-account-sync` | `chpwd` hook that applies the mapped account to the shell |

### Alias

- `ghu` — `gh-account-select`

This plugin's behavior is covered by the bats suite in `tests/` — see
[Testing](../../development/04-testing.md).

For details, see [Automatic Git identity switching](../../guides/04-git-identity.md).

---

## repository-select.zsh

A shared fzf selector for [gh-qw](../gh-qw.md) managed checkouts, used by
both `go-to-repository.zsh` and `edit-repository.zsh`.

### Behavior

1. List every managed checkout with `gh qw list --worktree`, which reports
   every configured root's main worktrees and, with `--worktree`, their
   linked worktrees as `<host>/<owner>/<repo>@<branch>`
2. Hide the `github.com/` prefix in the fzf display while keeping the canonical
   host-qualified spec in a hidden field, so other hosts stay unambiguous
3. Resolve the selected spec to an absolute path. `gh-qw` has no `path`
   command, so this is `gh qw list --worktree --exact --full-path` for a spec
   with an `@<branch>` suffix, or plain `gh qw list --exact --full-path`
   otherwise — omitting `--worktree` for a bare identity matters, because
   `--worktree --exact` without a suffix matches a repository's main worktree
   **and** every one of its linked worktrees
4. Treat empty output as "not found", since `list` exits `0` with nothing
   printed when no entry matches
5. Verify that the resolved directory exists
6. Print the absolute path on stdout

It writes a message to stderr and returns non-zero when `gh` is missing, the
listing is empty, the selection cannot be resolved, or the resolved path does
not exist.

### Interface

```zsh
repository-select-path "initial query" [extra fzf options...]
```

---

## go-to-repository.zsh

Select a [gh-qw](../gh-qw.md) managed checkout with fzf and `cd` into it.

### Behavior

1. Call `repository-select-path` with the current command line as the initial
   query
2. `cd` into the returned absolute path
3. Redraw the prompt when it was invoked as a ZLE widget

### Keybinding

- `C-]` — Invoke as a ZLE widget

### Alias

- `ggr`

---

## edit-repository.zsh

Select a [gh-qw](../gh-qw.md) managed checkout with fzf and open it in Neovim.

### Behavior

1. Call `repository-select-path` to get the absolute path of a checkout
2. Run `nvim <path>` via `run-selected-command`

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

| Key | Action |
| ------------ | ---------------------------------------------------------- |
| `↑` (`^[[A`) | Search backward through history using the text being typed |
| `↓` (`^[[B`) | Search forward through history using the text being typed |

---

## zshaddhistory.zsh

Skip recording a command in history if the immediately previous command failed (exit code ≠ 0).

### Behavior

Define the `zshaddhistory` hook function and return `false` when `$?` is not 0 (= do not add to history).
