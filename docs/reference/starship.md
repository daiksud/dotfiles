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
| directory               | `#769ff0`  | `#e3e5e5`  | Current directory or qwt worktree identifier |
| git_branch / git_status | `#394260`  | `#769ff0`  | Branch name + status, or Git icon + status and base warning for qwt |
| languages               | `#212736`  | `#769ff0`  | Node.js / Bun / Rust / Go / PHP versions |
| time                    | `#1d2230`  | `#a0a9cb`  | Current time (`HH:MM`)                   |

## Module settings

### Current directory

The `custom.cwd` module renders the directory segment. Outside a
[gh-qwt](./gh-qwt.md) worktree, it keeps every path component: paths inside the
home directory use `~` as their prefix, while paths outside it remain absolute.

For a gh-qwt worktree, the shared
`dotfiles/zsh/starship-qwt-worktree.sh` helper validates the `.bare` directory
and repository `.git` pointer, then displays `owner/repo/branch`. From a
subdirectory of the worktree, it appends the path relative to the worktree
root as `owner/repo/branch/path/to/subdir`. This preserves branch names that
contain `/`.

### Git branch

The `custom.git_branch` module displays the branch in ordinary Git worktrees.
In gh-qwt worktrees, it displays the Git icon `` without a branch name because
`custom.cwd` already includes the branch in its `owner/repo/branch` label.
Detached HEAD states display `HEAD`.

### qwt base warning

The `custom.qwt_base_warning` module appears in yellow when `origin/main` is
not an ancestor of the qwt worktree's `HEAD`. Its
` origin/main +N` label reports the number of commits reachable from
`origin/main` that the worktree does not contain.

Fetch the remote and then merge or rebase `origin/main` into the worktree
according to the repository workflow to remove the warning. The module does not
render until an `origin/main` reference is available locally.

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
