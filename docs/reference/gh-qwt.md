# gh-qwt

This is the reference for managing GitHub repositories and git worktrees together with the `gh-qwt` GitHub CLI extension.

## Overview

[gh-qwt](https://github.com/daiksud/gh-qwt) (`daiksud/gh-qwt`) is a GitHub CLI extension that clones a repository **once** as a bare git database and gives every branch its own worktree directory. It unifies the two roles previously covered by separate extensions in this repository: cloning/listing repositories (formerly `gh-q`, see [ADR 0004](../development/99-adr/0004-gh-q.md)) and managing per-branch worktrees (formerly `gh-wt`, see [ADR 0007](../development/99-adr/0007-gh-wt.md)). For the reasoning behind consolidating onto `gh-qwt`, see [ADR 0008](../development/99-adr/0008-gh-qwt.md).

Because every branch of a repository shares the same bare object database, checking out another branch never requires stashing, re-cloning, or thrashing a single working tree.

## Setup

The `gh-qwt` extension is installed automatically by `scripts/100-gh-extensions.sh` (see [Script list](./scripts.md)). To install it manually:

```bash
gh extension install daiksud/gh-qwt
```

## qwt root resolution

`gh qwt` stores repositories below a single **qwt root** directory, resolved in this order:

1. `QWT_ROOT` environment variable
2. `git config --get qwt.root`
3. Default: `~/qwt`

This is independent from `gh-q`'s old `~/ghq` directory and from ghq's `GHQ_ROOT`; existing clones under `~/ghq` are not read or migrated automatically.

## Directory layout

Repository paths omit the host segment and follow `<qwt_root>/<owner>/<repo>/<branch>`:

```text
~/qwt/cli/cli/
  .bare/              # bare git database (git clone --bare)
  .git                # file containing exactly: gitdir: ./.bare
  trunk/              # default-branch worktree, created by `gh qwt get`
  fix/parser/         # feature-branch worktree, created by `gh qwt add`
```

The `.git` pointer file uses a relative target (`gitdir: ./.bare`), so the whole repository directory is relocatable as long as `.bare/` and every worktree move together. Branch names containing `/` create nested worktree directories, so a branch named `feat` cannot coexist with a branch named `feat/x` (they need the same path for different purposes).

## Usage

```bash
# Clone a repository (bare) and create its default-branch worktree
gh qwt get cli/cli

# Create a worktree for another branch, from inside an existing worktree
gh qwt add fix/parser

# List every repository and worktree as a flat, sorted owner/repo/branch list
gh qwt list

# Remove a single worktree (run from inside the repository)
gh qwt remove fix/parser

# Remove worktrees whose branch is gone from the remote
gh qwt prune

# Print a path for shell scripting (see Shell shortcuts below)
gh qwt path cli/cli/fix/parser
```

## Command list

| Command | Description |
| --- | --- |
| `gh qwt get <owner>/<repo>\|<url>` | Clone a repository as a bare database and create a worktree for the default (or `--branch`) branch |
| `gh qwt add <branch>` | Create a worktree for a new or existing branch in the current (or `--repo`) repository |
| `gh qwt list [<query>] [-e\|--exact] [-p\|--full-path]` | List repositories and worktrees as a flat, sorted `owner/repo/branch` list, optionally filtered and/or printed as absolute paths |
| `gh qwt remove <branch>\|<owner>/<repo>\|<owner>/<repo>/<branch>` (aliased `rm`) | Remove a single worktree, or an entire repository when given `owner/repo` from outside it |
| `gh qwt root` | Print the resolved qwt root |
| `gh qwt path [<owner>/<repo>[/<branch>]]` | Print an absolute path (root, repository directory, or worktree path) for `cd` |
| `gh qwt prune` | Remove worktrees whose branch is gone from the remote, discovered from the current directory |

## Shell shortcuts

For interactive shells, this repository provides zsh functions built on `gh qwt list` and `gh qwt root`:

- `ggr` (`go-to-qwt-repository`, bound to `C-]`) — fzf-selects a repository or worktree and `cd`s into it
- `egr` (`edit-qwt-repository`) — fzf-selects a repository or worktree and opens it in `nvim`

It also provides a `ghq` shortcut that invokes `gh qwt` and uses `gh`'s own zsh completion. See `dotfiles/zsh/ghq.zsh` for the implementation.

See [Zsh plugins](./zsh/plugins.md) for details.

## Differences from the former `gh-q` / `gh-wt` setup

> [!IMPORTANT]
> `gh-qwt` does not back worktrees with copy-on-write (no OverlayFS on Linux, no APFS `clonefile(2)` on macOS). `gh qwt add`/`get` use a plain `git worktree add` against the shared bare repository, so only the git object database is shared — each worktree's checked-out files are still fully copied. This was the main benefit of the former `gh-wt` extension (see [ADR 0007](../development/99-adr/0007-gh-wt.md)) and is not available with `gh-qwt`.

> [!NOTE]
> `gh-qwt` has no built-in "select with fzf, then run a command" dispatch (there is no equivalent to the former `gh q -- <cmd>` / `gh wt -- <cmd>` / `gh wt <cmd>`). It only prints paths (`gh qwt path`, `gh qwt list --full-path`); combine these with a shell function such as `ggr`/`egr` above, or `cd "$(gh qwt path <spec>)" && <command>`, to act on the result.

## References

- [gh-qwt repository](https://github.com/daiksud/gh-qwt)
- For the background behind this technology choice, see [ADR 0008](../development/99-adr/0008-gh-qwt.md)
