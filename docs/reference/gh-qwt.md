# gh-qwt

This is the reference for managing GitHub repositories and git worktrees together with the `gh-qwt` GitHub CLI extension.

## Overview

[gh-qwt](https://github.com/daiksud/gh-qwt) (`daiksud/gh-qwt`) is a GitHub CLI extension that keeps **one ordinary, ghq-compatible primary clone** per repository and gives every other branch its own **external linked worktree**. It unifies the two roles previously covered by separate extensions in this repository: cloning/listing repositories (formerly `gh-q`, see [ADR 0004](../development/99-adr/0004-gh-q.md)) and managing per-branch worktrees (formerly `gh-wt`, see [ADR 0007](../development/99-adr/0007-gh-wt.md)). For the reasoning behind consolidating onto `gh-qwt`, see [ADR 0008](../development/99-adr/0008-gh-qwt.md); for the move to the ghq-compatible layout, see [ADR 0019](../development/99-adr/0019-gh-qwt-ghq-layout.md).

The primary checkout is a normal clone with a real `.git` directory, so `ghq`, `git`, and every other standard tool keep working with it. Linked worktrees live in a separate tree and share that clone's git common directory, so checking out another branch never requires stashing, re-cloning, or thrashing a single working tree.

> [!WARNING]
> gh-qwt v0.16.0 replaced the previous layout incompatibly. The bare git
> database (`.bare/`) under a dedicated qwt root is gone, and ordinary commands
> never open or adopt a legacy repository implicitly. Convert each legacy
> repository explicitly with `gh qwt migrate` (start with `--dry-run`), and read
> the upstream
> [upgrade guide](https://daiksud.github.io/gh-qwt/guides/upgrading-to-ghq-layout/)
> before moving any repository that contains uncommitted work.

## Setup

The `gh-qwt` extension is installed automatically by `scripts/100-gh-extensions.sh` (see [Script list](./scripts.md)). To install it manually:

```bash
gh extension install daiksud/gh-qwt
```

The real `ghq` binary is installed from the Brewfile (see [Tool list](./tools.md)). Both tools read the same root configuration, so a repository cloned by either one is discoverable by the other.

## Root resolution

`gh qwt` uses **ghq's** root configuration. `QWT_ROOT` and `git config qwt.root` were removed and are no longer read.

1. `GHQ_ROOT`, when non-empty, is the only source. It is a platform path list (for example `first:second` on Unix) and its first entry is the primary root
2. Otherwise every `ghq.root` Git config value is used, reversed so that the last configured value is the primary root
3. Otherwise the primary and only root is `~/ghq`

URL-specific `ghq.<pattern>.root` values also participate in discovery, matching ghq's own placement behavior.

| Command | Output |
| --- | --- |
| `gh qwt root` | The primary ghq clone root |
| `gh qwt root --all` | Every discovery root, ordered and deduplicated |

Linked worktrees are kept outside every ghq root. A repository pins its external worktree root when it is cloned or adopted: `qwt.worktreeroot` from the system, global, or command scope when configured, otherwise `<owning-ghq-root>-worktrees`. The resolved path is stored per repository, so changing the global value later never moves an existing checkout.

## Directory layout

Canonical paths always include the host segment:

```text
<ghq-root>/<host>/<owner>/<repo>/                     # primary checkout, real .git directory
<ghq-root>-worktrees/<host>/<owner>/<repo>/<branch>/  # linked worktree, .git pointer file
```

With the default roots, this repository's primary checkout is `~/ghq/github.com/daiksud/dotfiles`, and a `fix/parser` worktree of it is `~/ghq-worktrees/github.com/daiksud/dotfiles/fix/parser`.

The primary checkout stays attached to the pinned default branch and provides the git common directory for every linked worktree. Branch names containing `/` create nested directories, so a branch named `feat` cannot coexist with a branch named `feat/x` — they need the same path for different purposes.

### Managed metadata

A managed repository records its own metadata in repository-local Git config. Because linked worktrees share the primary checkout's git common directory, these keys are readable from every worktree:

| Key | Contents |
| --- | --- |
| `qwt.managed` | `true` when the repository is managed by gh-qwt |
| `qwt.identity` | Canonical `<host>/<owner>/<repo>` identity, for example `github.com/daiksud/dotfiles` |
| `qwt.defaultbranch` | Pinned default branch held by the primary checkout |
| `qwt.worktreeroot` | Pinned external worktree root for this repository |

Read these keys to detect a managed checkout and its identity. Since the identity carries the host, repositories with the same `owner/repo` on different GitHub hosts no longer share a path; when two roots must stay apart for another reason, configure separate ghq roots instead.

## Prompt display

Starship has no gh-qwt integration. Both the primary checkout and every linked worktree are ordinary Git working trees, so Starship's built-in `directory` and `git_branch` modules already show the correct path and branch. See [Starship](./starship.md) for the prompt configuration.

## GitHub CLI authentication

There is no repository-level `.gh/` directory anymore, and `GH_CONFIG_DIR` is no longer set. Every account lives in `gh`'s single user-level configuration, and the `gh-account.zsh` plugin decides which account the current directory uses: it resolves the canonical `<host>/<owner>/<repo>` identity of `origin`, looks it up in the central mapping file `~/.config/gh/repos.json`, and exports that account's token and Git identity for the current shell only.

The primary checkout and its linked worktrees share the same `origin`, so they resolve to the same account without any per-worktree configuration. See [Automatic Git identity switching](../guides/04-git-identity.md) for the full behavior and [Zsh plugins](./zsh/plugins.md) for the plugin's functions.

## Usage

```bash
# Clone or adopt the primary checkout of a repository
gh qwt get cli/cli

# Create a linked worktree for an existing branch, from inside the repository
gh qwt add fix/parser

# Create a linked worktree for a genuinely new branch
gh qwt add --new task/cleanup

# Base a new worktree on a specific ref
gh qwt add release/fix --from origin/release

# List the managed worktrees of the current repository
gh qwt list

# List every managed checkout across all configured roots
gh qwt list --all

# Remove a single linked worktree
gh qwt remove fix/parser

# Remove linked worktrees whose branch is gone from the remote
gh qwt prune

# Print a path for shell scripting (see Shell shortcuts below)
gh qwt path github.com/cli/cli/fix/parser

# Inspect a legacy-layout repository without changing anything
gh qwt migrate --dry-run /absolute/path/to/legacy/repository
```

## Command list

| Command | Description |
| --- | --- |
| `gh qwt get [-b\|--branch <branch>] [--host <host>] <repo>` | Clone or adopt the primary checkout. Without `--branch`, or with the pinned default branch, it prints the primary path; another branch returns or creates its linked worktree. `--host` defaults to `github.com` |
| `gh qwt add [--repo <owner>/<repo>] [--from <ref>] [--new] <branch>` | Create an external linked worktree. An existing local or remote-tracking branch is attached; `--new` requires that no such branch exists and bases the branch on `--from` or the pinned default |
| `gh qwt list [<query>] [-e\|--exact] [-p\|--full-path] [--all]` | List managed worktrees of the current repository, or of every configured root with `--all`. `--exact` accepts both `<host>/<owner>/<repo>/<branch>` and short `<owner>/<repo>/<branch>` specs; `--full-path` prints registered absolute paths |
| `gh qwt remove [--repo <owner>/<repo>] [--force] [--delete-branch] <spec>` (aliased `rm`) | Remove one linked worktree, or a whole managed repository when given `<owner>/<repo>` outside it. Since v0.15 it can target any managed repository, not only the current one |
| `gh qwt root [--all]` | Print the primary ghq clone root, or every ordered discovery root |
| `gh qwt path [<spec>]` | Print the primary root, a repository's primary checkout, or a branch's worktree path |
| `gh qwt prune [-y\|--force]` | Fetch `origin --prune`, then remove clean external worktrees whose tracked remote branch is gone |
| `gh qwt migrate [--dry-run] [--yes] <legacy-repo-path>` | Explicitly inspect or convert a legacy-layout repository. This is the only command that touches the old layout |
| `gh qwt shell-init <bash\|zsh\|fish>` | Print optional shell integration that `cd`s into the path printed by a successful `add` |

### Specification form

`<owner>/<repo>` is shorthand for `github.com/<owner>/<repo>`, so `get`, `add --repo`, `remove --repo`, and `list --exact` accept the short form. A **branch** spec passed to `gh qwt path` must be host-qualified: `gh qwt path github.com/daiksud/dotfiles/main` resolves, while `gh qwt path daiksud/dotfiles/main` fails with `no managed repository`.

> [!IMPORTANT]
> `gh qwt path` also prints the deterministic **planned** path of a worktree
> that does not exist yet, so its output is not evidence that a worktree
> exists. Confirm existence with `gh qwt list ... --exact --full-path` or by
> checking the directory.

`gh qwt list` without `--all` is scoped to the current repository and fails with `gh-qwt: repository is outside configured ghq roots` when it runs inside a Git repository that no configured root contains. Use `--all` whenever the command must work from anywhere. Listing output is host-qualified (`<host>/<owner>/<repo>/<branch>`), and the primary checkout appears with its current branch, so `github.com/daiksud/dotfiles/main` resolves to `~/ghq/github.com/daiksud/dotfiles`.

## Agent session integration

The canonical personal instructions at `dotfiles/agent-instructions.md` are
linked to the paths loaded by GitHub Copilot, Codex, and Claude Code (see
[Using skills](../guides/06-skills.md)). They route Pull Request requests to
the matching shared skill.

The shared PR skills do not require `gh-qwt`. They operate only in an ordinary
clone where the user invokes them; their definitions under `dotfiles/skills/`
remain the authoritative procedure. This page documents explicit `gh-qwt` use
for interactive repository and worktree management.

## Pull Request skill relationship

The shared `pr-create`, `pr-fix`, and `pr-merge` Agent Skills do not provision
or reuse a `gh-qwt` worktree. They use the checkout where the user invoked the
skill:

| PR phase | Checkout behavior |
| --- | --- |
| Create | Create a feature branch in an ordinary clone only from an exactly synchronized default branch, or use a non-default branch that has no existing PR. |
| Fix | Require a clean ordinary clone of the exact PR head repository and branch, including the fork for a fork PR. |
| Merge | Require that same ordinary clone, merge one PR, leave the local branch checked out, and delete only an unchanged remote head branch. |

The skills still resolve canonical GitHub identities and re-check branch,
working-state, remote-head, review, and CI conditions before mutating a PR.
Concurrent PR work requires separate ordinary clones. See
[Using skills](../guides/06-skills.md) and
[ADR 0021](../development/99-adr/0021-pr-skills-invoking-checkout.md) for the
complete workflow.

## Shell shortcuts

For interactive shells, this repository provides zsh functions built on `gh qwt list --all` and `gh qwt path`:

- `qwt-select-path` — shared fzf selector that lists every managed checkout and prints the resolved, existing absolute path
- `ggr` (`go-to-qwt-repository`, bound to `C-]`) — selects a checkout and `cd`s into it
- `egr` (`edit-qwt-repository`) — selects a checkout and opens it in `nvim`

See [Zsh plugins](./zsh/plugins.md) for details. `gh qwt shell-init zsh` provides an independent upstream integration that enters a worktree right after `add`; this repository does not enable it.

## Differences from the former `gh-q` / `gh-wt` setup

> [!IMPORTANT]
> `gh-qwt` does not back worktrees with copy-on-write (no OverlayFS on Linux, no APFS `clonefile(2)` on macOS). `gh qwt add`/`get` use a plain `git worktree add` against the primary checkout, so only the git object database is shared — each worktree's checked-out files are still fully copied. This was the main benefit of the former `gh-wt` extension (see [ADR 0007](../development/99-adr/0007-gh-wt.md)) and is not available with `gh-qwt`.

> [!NOTE]
> `gh-qwt` has no built-in "select with fzf, then run a command" dispatch (there is no equivalent to the former `gh q -- <cmd>` / `gh wt -- <cmd>` / `gh wt <cmd>`). It only prints paths (`gh qwt path`, `gh qwt list --full-path`); combine these with a shell function such as `ggr`/`egr` above, or `cd "$(gh qwt path <spec>)" && <command>`, to act on the result.

## References

- [gh-qwt repository](https://github.com/daiksud/gh-qwt)
- [gh-qwt documentation](https://daiksud.github.io/gh-qwt/)
- [Upgrading to the ghq layout](https://daiksud.github.io/gh-qwt/guides/upgrading-to-ghq-layout/)
- For the background behind this technology choice, see [ADR 0008](../development/99-adr/0008-gh-qwt.md) and [ADR 0019](../development/99-adr/0019-gh-qwt-ghq-layout.md)
