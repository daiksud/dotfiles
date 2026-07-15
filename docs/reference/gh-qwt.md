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
same `gh` account and Copilot token.

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
| `gh qwt list [<query>] [-e\|--exact] [-p\|--full-path]` | List repositories and worktrees as a flat, sorted `owner/repo/branch` list, optionally filtered and/or printed as absolute paths |
| `gh qwt remove <branch>\|<owner>/<repo>\|<owner>/<repo>/<branch>` (aliased `rm`) | Remove a single worktree, or an entire repository when given `owner/repo` from outside it |
| `gh qwt root` | Print the resolved qwt root |
| `gh qwt path [<owner>/<repo>[/<branch>]]` | Print an absolute path (root, repository directory, or worktree path) for `cd` |
| `gh qwt prune` | Remove worktrees whose branch is gone from the remote, discovered from the current directory |

## Interactive session integration

`dotfiles/copilot-instructions.md` is loaded as `~/.copilot/copilot-instructions.md` in every interactive Copilot CLI session (see [Using skills](../guides/06-skills.md)). For repository tasks other than the PR workflows below, it records the invoking checkout's repository-relative working directory, branch, working state, and commit before resolving the expected `owner/repo/branch` target. When the source and target differ, it fetches the remote for the resolved repository and compares the recorded source commit with a matching tracking branch, remote branch, or chosen creation base, even when the source is dirty. An unrelated tracking remote is not used. Publishing, deliberately transferring, or explicitly leaving out ahead or diverged source history requires a choice; work does not continue in an ordinary source checkout.

The repository is considered an existing qwt repository only when its `.bare` directory exists, because `gh qwt path` also calculates paths for repositories and worktrees that have not been created. The source identity includes the GitHub host. Before an existing qwt repository is reused, its `origin` is resolved to a canonical GitHub repository and must match the full `host/owner/repo` identity. A missing repository is provisioned with the resolved host and branch explicitly.

An existing target is reused only after its branch and working state are inspected. If the source and target are different and either contains uncommitted changes, the instructions prevent silently abandoning or mixing those changes: migration must be deliberate and verified, or the session stops to ask how to proceed. Only a missing target is provisioned, with the repository passed explicitly to `get` or `add --repo`.

Before work begins, the target fetches `origin` and compares its commit with the remote branch, or with the selected default-branch base when the target branch has not been published. A clean target that is only behind is fast-forwarded, while a dirty behind target stops for direction. Ahead, diverged, or otherwise local-only target history requires an explicit choice instead of an automatic reset, rebase, push, or overwrite. A dormant local branch that previously tracked a now-missing remote branch is treated as a deletion, not as a new branch, and requires an explicit restore, publish, rename, or abandon decision. The recorded source-relative directory must have an existing counterpart that physically resolves inside the target worktree; missing directories and symlink escapes stop instead of falling back to the target root. Subsequent work runs from that verified counterpart.

PR requests are delegated directly from the invoking checkout to the matching skill before this general setup runs. This lets `pr-create` capture staged, unstaged, and untracked source changes before it selects and prepares its target worktree.

## Pull Request skill integration

The `pr-create`, `pr-fix`, and `pr-merge` Copilot skills use `gh-qwt` as their
only branch-workspace mechanism. They do not change the branch of the
checkout that started the skill.

| PR phase | qwt behavior |
| --- | --- |
| Create | Resolve the repository and create a feature worktree. A missing qwt repository is initialized with `get`; a new feature branch is then created with `add`. |
| Fix | Resolve the PR head repository and branch, including a fork head, then create or reuse that branch's worktree. |
| Merge | Keep the head worktree through final CI, then remove the clean worktree and local branch after GitHub confirms the squash merge. |

Before `add` is used in an existing qwt repository, the skills fetch
`origin --prune` from the repository root. `add` relies on cached remote refs,
so this refresh prevents a newly pushed PR branch from being mistaken for a
new branch. A missing remote PR branch is created with `get --branch`; a new
feature branch requires a default-branch `get` followed by `add`. A reused PR
worktree must be clean and either fast-forward to its remote head or stop on
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
