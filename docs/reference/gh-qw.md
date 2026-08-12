# gh-qw

This is the reference for managing GitHub repositories and Git worktrees together with the `gh-qw` GitHub CLI extension.

## Overview

[gh-qw](https://github.com/daiksud/gh-qw) (`daiksud/gh-qw`) is a GitHub CLI extension that keeps **one ordinary main clone** per repository, discoverable at an ordinary ghq-style path, and gives every other branch its own **linked worktree** under a separate root. It replaces the earlier `gh-qwt` extension in this repository; see [ADR 0027](../development/99-adr/0027-gh-qw.md) for why.

The main worktree is an ordinary clone with a real `.git` directory, so `git` and every other standard tool keep working with it. Linked worktrees live in a separate tree and share the main worktree's Git common directory, so checking out another branch never requires stashing, re-cloning, or thrashing a single working tree.

`gh-qw` writes no managed metadata into Git config, and it does not require the main worktree to stay on any particular branch. Both the main worktree and its linked worktrees are ordinary Git worktrees at every point; `gh-qw` only chooses their paths.

## Setup

The `gh-qw` extension is installed automatically by `scripts/100-gh-extensions.sh` (see [Script list](./scripts.md)). To install it manually:

```bash
gh extension install daiksud/gh-qw
```

## Identities

Every repository has a canonical identity:

```text
<host>/<owner>/<repo>
```

A linked worktree adds `@<branch>` to that identity, for example `github.com/cli/cli@fix/parser`. `<owner>/<repo>` is shorthand for `github.com/<owner>/<repo>` wherever a command accepts a repository selector.

## Root resolution

`gh-qw` reads its own configuration, never ghq's. `GHQ_ROOT` and `ghq.root` are read only by `gh qw migrate`, to locate legacy repositories to migrate; they have no effect on normal operation.

Repository roots, highest precedence first:

1. non-empty `GHQW_ROOT`, a platform path list (for example `first:second` on Unix) whose first entry is the primary root
2. `root` in `$XDG_CONFIG_HOME/ghqw/config.toml` (or `~/.config/ghqw/config.toml` when `XDG_CONFIG_HOME` is unset or relative)
3. otherwise the primary and only root is `~/ghqw`

The worktree root is a single path, resolved independently:

1. non-empty `GHQW_WORKTREE_ROOT`
2. `worktree_root` in the same configuration file
3. otherwise `$XDG_DATA_HOME/ghqw/worktrees`, or `~/.local/share/ghqw/worktrees` when unset

This repository does not set any of these, so both roots use their defaults.

| Command | Output |
| --- | --- |
| `gh qw root` | The primary repository root |
| `gh qw root --all` | Every configured repository root, in precedence order |

## Directory layout

Canonical paths always include the host segment:

```text
<repository-root>/<host>/<owner>/<repo>/                # main worktree, real .git directory
<worktree-root>/<host>/<owner>/<repo>/<branch>/          # linked worktree, .git pointer file
```

With the default roots, this repository's main worktree is `~/ghqw/github.com/daiksud/dotfiles`, and a `fix/parser` worktree of it is `~/.local/share/ghqw/worktrees/github.com/daiksud/dotfiles/fix/parser`.

Branch names containing `/` create nested directories, so a branch named `feat` cannot coexist with a branch named `feat/x` — they need the same path for different purposes.

## Prompt display

Starship has no gh-qw integration. Both the main worktree and every linked worktree are ordinary Git working trees, so Starship's built-in `directory` and `git_branch` modules already show the correct path and branch. See [Starship](./starship.md) for the prompt configuration.

## GitHub CLI authentication

`gh-qw`'s `get` and `worktree add` are the only commands that perform network-capable Git or GitHub API operations, and both delegate to `gh` (`gh repo clone`, `gh repo sync`, and the API used to look up a repository's default branch). Before either operation, `gh-qw` resolves which authenticated account to use for the repository's `<owner>` on its own: an explicit `GH_TOKEN`/`GITHUB_TOKEN`, then a valid cached choice, an owner-matching account, a sole authenticated account, or an interactive prompt.

This is independent from, and does not replace, this repository's own account selection. The `gh-account.zsh` plugin resolves the canonical `<host>/<owner>/<repo>` identity of `origin`, checks its repository override before its `<host>/<owner>` default in `~/.config/gh/repos.json`, and exports that account's token and Git identity for the current shell only. The main worktree and its linked worktrees share the same `origin`, so they resolve to the same account without any per-worktree configuration. See [Automatic Git identity switching](../guides/04-git-identity.md) for the full behavior and [Zsh plugins](./zsh/plugins.md) for the plugin's functions.

## Usage

```bash
# Clone or update the main worktree of a repository
gh qw get cli/cli

# Create a linked worktree for an existing or new branch, from inside the repository
gh qw worktree add fix/parser

# Base a new worktree on a specific ref
gh qw worktree add -b task/cleanup origin/main

# List every main worktree across all configured roots
gh qw list

# Also list every linked worktree
gh qw list --worktree

# Remove a whole managed repository (prompts for confirmation)
gh qw rm cli/cli

# Remove a single linked worktree
gh qw worktree remove fix/parser

# Prune linked worktrees whose Git metadata or directory is stale
gh qw worktree prune

# Resolve an identity to its absolute path for shell scripting (see Shell shortcuts below)
gh qw list --exact --full-path github.com/cli/cli
```

## Command list

| Command | Description |
| --- | --- |
| `gh qw get` / `gh qw clone` `[-u\|--update] [-b\|--branch <branch>] [<repo>...]` | Clone a missing repository's main worktree, or update an existing one |
| `gh qw list [<query>] [-e\|--exact] [-p\|--full-path] [--unique] [--worktree]` | List main worktrees, and linked worktrees with `--worktree`, across every configured root |
| `gh qw root [--all]` | Print the primary repository root, or every configured root in order |
| `gh qw rm [--dry-run] <repo>[@<branch>]` | Remove a whole managed repository (with confirmation), or one linked worktree with `@<branch>` |
| `gh qw migrate [-y] [--dry-run] [<directory>]` | Migrate a legacy ghq-layout repository, or discover and migrate every one under legacy `ghq.root` locations |
| `gh qw worktree add [-R <repo>] [-b\|-B] [--detach] [--orphan] [-f] <branch> [<commit-ish>]` | Create a linked worktree at its deterministic branch path |
| `gh qw worktree list [-R <repo>] [-v] [--porcelain] [--full-path]` | List one repository's registered worktrees, main first |
| `gh qw worktree remove [-R <repo>] [-f] <branch>` | Remove one linked worktree |
| `gh qw worktree prune [-R <repo>] [-n\|--dry-run] [-v] [--expire <expire>]` | Prune stale Git worktree metadata and orphaned worktree directories |

There is no `path` command. Resolve an identity to a path with `gh qw list --exact --full-path` (see [Path resolution](#path-resolution-there-is-no-path-command) below), and no `shell-init`; combine `list`/`worktree` output with a shell function such as `ggr`/`egr` below to act on a selection.

### Local repository selectors

Every command that selects an existing repository accepts `<repo>` (final-component match), `<owner>/<repo>`, or `<host>/<owner>/<repo>`. Selection is not fuzzy; a selector matching more than one repository is ambiguous and fails. A `worktree` subcommand without `-R` resolves the repository from the current directory, whether it is inside the main worktree or one of its linked worktrees.

### Path resolution: there is no `path` command

Unlike the former `gh qwt path`, `gh-qw` has no dedicated path-printing command. Resolve an identity with `list`:

```bash
# Main worktree only
gh qw list --exact --full-path github.com/cli/cli

# One linked worktree
gh qw list --worktree --exact --full-path "github.com/cli/cli@fix/parser"
```

> [!IMPORTANT]
> `--worktree --exact` **without** an `@<branch>` suffix matches a repository's
> main worktree **and every one of its linked worktrees**, not just the main
> one. Omit `--worktree` when resolving a bare `<host>/<owner>/<repo>` identity
> so only the main worktree matches; add `--worktree` only when the spec has an
> `@<branch>` suffix.

`list` exits `0` even when nothing matches, printing nothing; empty output, not a nonzero exit status, is the "not found" signal.

## Agent session integration

The canonical personal instructions at `dotfiles/agent-instructions.md` are
linked to the paths loaded by GitHub Copilot, Codex, and Claude Code (see
[Using skills](../guides/06-skills.md)). They route Pull Request requests to
the matching shared skill.

The shared PR skills do not require `gh-qw`. They operate in the Git checkout
where the user invokes them, including a gh-qw main worktree or linked
worktree; their definitions under `dotfiles/skills/` remain the authoritative
procedure. This page documents explicit `gh-qw` use for interactive repository
and worktree management.

## Pull Request skill relationship

The shared `pr-create`, `pr-fix`, and `pr-merge` Agent Skills do not provision
or reuse a `gh-qw` worktree. They use the checkout where the user invoked the
skill:

| PR phase | Checkout behavior |
| --- | --- |
| Create | Create a feature branch in the invoking checkout only from an exactly synchronized default branch, or use a non-default branch that has no existing PR. |
| Fix | Require a clean invoking checkout of the exact PR head repository and branch, including the fork for a fork PR. |
| Merge | Require that same checkout, merge one PR, leave the local branch checked out, and delete only an unchanged remote head branch. |

The skills still resolve canonical GitHub identities and re-check branch,
working-state, remote-head, review, and CI conditions before mutating a PR.
Concurrent PR work requires separate checkouts, such as linked worktrees or
ordinary clones. See
[Using skills](../guides/06-skills.md) and
[ADR 0021](../development/99-adr/0021-pr-skills-invoking-checkout.md) and
[ADR 0027](../development/99-adr/0027-gh-qw.md) for the
complete workflow.

## Shell shortcuts

For interactive shells, this repository provides zsh functions built on `gh qw list --worktree` and `gh qw list --exact --full-path`:

- `repository-select-path` — shared fzf selector that lists every managed checkout and prints the resolved, existing absolute path
- `ggr` (`go-to-repository`, bound to `C-]`) — selects a checkout and `cd`s into it
- `egr` (`edit-repository`) — selects a checkout and opens it in `nvim`

See [Zsh plugins](./zsh/plugins.md) for details.

## References

- [gh-qw repository](https://github.com/daiksud/gh-qw)
- [gh-qw documentation](https://daiksud.github.io/gh-qw/)
- For the background behind this technology choice, see [ADR 0027](../development/99-adr/0027-gh-qw.md)
