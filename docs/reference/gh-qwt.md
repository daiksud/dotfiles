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
  .gh/                # GitHub CLI authentication shared by every worktree
  trunk/              # default-branch worktree, created by `gh qwt get`
  fix/parser/         # feature-branch worktree, created by `gh qwt add`
```

Repositories with the same `owner/repo` on different GitHub hosts therefore cannot safely share one qwt root. Verify the existing bare repository's canonical `origin` before reuse, and use a separate `QWT_ROOT` when both repositories are needed.

The `.git` pointer file uses a relative target (`gitdir: ./.bare`), so the whole repository directory is relocatable as long as `.bare/` and every worktree move together. Branch names containing `/` create nested worktree directories, so a branch named `feat` cannot coexist with a branch named `feat/x` (they need the same path for different purposes).

## Prompt display

Inside a qwt worktree, the Starship directory segment displays
`owner/repo/branch`, including when the current directory is below the worktree
root. It verifies the shared `.bare` directory and `.git` pointer, so ordinary
Git repositories retain their normal path display. The separate Git branch
segment displays only the Git icon ``, because this label already includes the
branch. See [Starship](./starship.md) for the complete prompt behavior.

When `origin/main` is not an ancestor of a qwt worktree's `HEAD`, the prompt
also shows a yellow ` origin/main +N` warning. `N` is the number of
`origin/main` commits missing from that worktree; fetch and then merge or rebase
the remote branch according to the repository workflow.

## GitHub CLI authentication

The `gh-config-dir.zsh` plugin recognizes the `.bare/` directory and `.git`
pointer created by gh-qwt. It sets `GH_CONFIG_DIR` to the repository-level
`.gh/` directory, so every branch worktree of the same repository uses the
same `gh` account. The plugin also synchronizes `COPILOT_GITHUB_TOKEN` for
GitHub Copilot CLI; Codex and Claude Code continue to use their own agent
authentication while sharing the same `gh` session for GitHub operations.

Authentication stored in older worktree-specific directories is not copied,
because it can contain tokens for different accounts. In any existing worktree,
run the following once to initialize the shared `.gh/` directory:

```bash
gh auth login
```

See [Automatic Git identity switching](../guides/04-git-identity.md) for the
full account and signing-key behavior.

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
| `gh qwt get [--host <host>] [--branch <branch>] <owner>/<repo>\|<url>` | Clone a repository as a bare database and create a worktree for the requested or default branch |
| `gh qwt add <branch>` | Create a worktree for a new or existing branch in the current (or `--repo`) repository |
| `gh qwt list [<query>] [-e\|--exact] [-p\|--full-path]` | List repositories and worktrees as a flat, sorted `owner/repo/branch` list, optionally filtered and/or printed as absolute paths; `--exact` matches `branch`, `repo/branch`, or `owner/repo/branch` |
| `gh qwt remove <branch>\|<owner>/<repo>\|<owner>/<repo>/<branch>` (aliased `rm`) | Remove a single worktree, or an entire repository when given `owner/repo` from outside it |
| `gh qwt root` | Print the resolved qwt root |
| `gh qwt path [<owner>/<repo>[/<branch>]]` | Print an absolute path (root, repository directory, or worktree path) for `cd` |
| `gh qwt prune` | Remove worktrees whose branch is gone from the remote, discovered from the current directory |

## Agent session integration

The canonical personal instructions at `dotfiles/agent-instructions.md` are
linked to the paths loaded by GitHub Copilot, Codex, and Claude Code (see
[Using skills](../guides/06-skills.md)). They apply the same `gh-qwt` safety
workflow to general repository tasks in all three agents.

At a high level, the workflow records the invoking checkout, verifies the full
GitHub host and repository identity, checks both source and target state, and
uses only an explicitly resolved qwt worktree. It stops for a decision instead
of silently abandoning dirty changes or rewriting ahead, diverged, deleted, or
otherwise ambiguous history. Machine-readable safety probes bypass RTK
filtering so their raw output and exit status remain reliable.

PR requests use the matching shared skill before the general setup. This lets
`pr-create` capture staged, unstaged, and untracked source changes before it
selects and prepares its target worktree. The canonical instruction file and
the skill definitions under `dotfiles/skills/` remain the authoritative
procedure; this page describes their integration without copying them.

## Pull Request skill integration

The shared `pr-create`, `pr-fix`, and `pr-merge` Agent Skills use `gh-qwt` as
their only branch-workspace mechanism in GitHub Copilot, Codex, and Claude
Code. They do not change the branch of the checkout that started the skill.

| PR phase | qwt behavior |
| --- | --- |
| Create | Resolve the repository and create a feature worktree. A missing qwt repository is initialized with `get`; a new feature branch is then created with `add`. |
| Fix | Resolve the PR head repository and branch, including a fork head, then create or reuse that branch's worktree. |
| Merge | Keep the head worktree through final CI, then remove the clean worktree and local branch after GitHub confirms the squash merge. |

Since qwt paths omit the GitHub host, every PR skill records the canonical
remote URL and full lowercase `<host>/<owner>/<repo>` identity. Before any
existing qwt repository is listed, fetched, reused, pushed, or removed, its
bare `origin` must resolve to that same identity. New repositories are created
with the verified `--host` and checked again before use. A host collision stops
the workflow and requires a separate `QWT_ROOT`; the skills never repoint the
existing `origin`.

A calculated path is not sufficient evidence that a branch is a qwt worktree.
Before reuse and after each `get` or `add`, the skills require the raw
`gh qwt list --exact --full-path` output to contain the worktree created by
that command byte-for-byte. A default-branch bootstrap is checked at the
default path before the feature target is created and checked after `add`. An
unregistered occupied path is reported as a collision and is never inspected,
edited, pushed, or removed as the PR target. An occupied repository path
without the qwt `.bare` database also stops before `get` instead of being
initialized in place.

Before `add` is used in an existing qwt repository, the skills fetch
`origin --prune` from the repository root. `add` relies on cached remote refs,
so this refresh prevents a newly pushed PR branch from being mistaken for a
new branch. A missing local qwt repository for an existing remote PR branch is
created with `get --branch`; a new feature branch requires a default-branch
`get` followed by `add`. A reused PR worktree must be clean and either
fast-forward to its remote head or stop on
an ahead/diverged branch.

When `pr-create` starts from a dirty default branch, it transfers staged,
unstaged, and non-ignored untracked changes through a named stash and validates
the target before clearing the source. For an ordinary clone, the stash is
temporarily bundled into the qwt repository so the index state is preserved.
If the default branch has local commits or the qwt path is unsafe, the skill
stops rather than resetting a branch or falling back to a normal checkout.

After a confirmed merge, `pr-merge` removes the worktree and local branch with
`gh qwt remove --delete-branch`. It runs that command from `gh qwt root`,
because an `owner/repo/branch` argument is only interpreted as an explicit
worktree spec outside a qwt repository. It then deletes the head remote branch
only when its current ref still matches the verified PR head SHA, using a
lease-protected push. This supports fork PR cleanup without risking deletion
of a branch that changed after the merge check.

The self-approval request used by `pr-merge` is also persistent across its
review/CI retry loop. The label is applied at most once, the three-minute
deadline is measured from that one request, and an approval that remains valid
is reused after a retry instead of requiring a newer review.

> [!IMPORTANT]
> PR skills never use `git switch`, `git checkout`, ordinary `git worktree`,
> or a normal-clone fallback. This constraint applies only to the skills; it
> does not change interactive Git usage.

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
