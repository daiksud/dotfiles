# Using skills

This is a guide for getting started quickly with custom Copilot CLI skills.

## Prerequisites

- dotfiles are already installed (`install.sh` has been run)
- GitHub Copilot CLI is already installed
- The `gh-qwt` GitHub CLI extension is available (it is installed by the
  dotfiles setup)

## Available skills

| Skill       | What it does                                                                              |
| ----------- | ----------------------------------------------------------------------------------------- |
| `pr-create` | Automatically creates a draft PR from the current changes                                 |
| `pr-fix`    | Fixes CI errors, handles reviews, and resolves merge conflicts for the specified PR       |
| `pr-merge`  | Loops `pr-fix` and Copilot Code Review to zero findings, then approves, waits for CI, and squash merges one or more PRs |

## How PR skills use worktrees

The PR skills do not switch the branch of the checkout where you invoked
Copilot. They create or reuse a [`gh-qwt`](../reference/gh-qwt.md) worktree
for the feature or PR head branch, then perform Git operations only in that
path.

- On a first use, the skill can provision the repository under your qwt root.
- `pr-create` safely transfers staged, unstaged, and non-ignored untracked
  changes from a default-branch worktree into the new feature worktree.
- If the default branch has local commits, the skill stops instead of resetting,
  rebasing, or pushing that branch automatically.
- A branch name that collides with another qwt path, such as `feat` and
  `feat/login`, stops with an error rather than falling back to a branch
  switch.
- `pr-fix` works in the PR head worktree, including a fork's repository when
  applicable. `pr-merge` removes the clean worktree after a successful merge.

> [!IMPORTANT]
> PR skills intentionally do not use `git switch`, `git checkout`, ordinary
> `git worktree`, or a normal-clone fallback. This policy applies to the
> skills; it does not change your normal interactive Git commands.

## Use `pr-create`

With your changes staged:

```bash
copilot -p "/pr-create"
```

If you want to explain the reason for the change:

```bash
copilot -p "/pr-create Refactor authentication logic, related to #42"
```

In an interactive session, you can also start it with `/pr create` (described later).

### What happens

1. Checks for a corresponding Task (Issue) and suggests creating one if it does not exist
2. Reads the diff and comes up with a commit message
3. Creates or reuses an isolated qwt feature worktree and safely moves
   uncommitted changes there when needed
4. Commits and pushes the feature branch from that worktree
5. Creates a draft PR
6. Sets you as the assignee

## Use `pr-fix`

```bash
copilot -p "/pr-fix PR #42"
```

In an interactive session, you can also start it with `/pr fix` (described later).

### What happens

1. Resolves the PR head repository and creates or reuses its qwt worktree
2. Detects and resolves merge conflicts
3. Identifies CI failures from logs and fixes them (repeating until they pass)
4. Checks review comments and applies reasonable fixes (any comment you reply "対応しない" to is left unchanged, and the reason is recorded in the PR body)
5. Performs a local review before pushing
6. Replies to each review comment with what was addressed and resolves the thread

You can also specify a mode:

```bash
copilot -p "/pr-fix ci #42"        # CI failures only
copilot -p "/pr-fix feedback #42"  # Review comments only
copilot -p "/pr-fix conflicts #42" # Conflicts only
```

## Use `pr-merge`

```bash
copilot -p "/pr-merge 42"
```

Multiple PRs can be given at once, separated by spaces; they are processed one at a time:

```bash
copilot -p "/pr-merge 42 43"
```

In an interactive session, you can also start it with `/pr merge` (described later).

### What happens

For each PR number given:

1. Runs `pr-fix` and requests a review from Copilot Code Review, repeating until there are no unresolved findings (up to 10 attempts)
2. Takes the PR out of Draft and applies the `self approval` label
3. Waits for the repository's existing self-approval automation to approve the PR (up to 3 minutes)
4. Waits for CI to go green, going back to step 1 if a merge conflict or a CI failure shows up
5. Squash merges the PR once everything is green, then removes its qwt
   worktree and branch workspace

If a PR cannot be brought to a mergeable state, it is skipped (with the reason recorded) so the rest of the batch keeps going, and a summary is reported at the end.

> [!IMPORTANT]
> `pr-merge` waits for an existing automation that approves PRs labeled `self approval` — it does not create that automation. It also expects the `self approval` label to already exist in the repository.

## Interactive session integration

`install.sh` creates a symbolic link from `dotfiles/copilot-instructions.md` to `~/.copilot/copilot-instructions.md`.
This file contains the following instructions and is always loaded in interactive sessions:

- For repository tasks other than the PR workflows, record the invoking checkout's repository-relative working directory and working state, identify an existing qwt repository by its `.bare` directory, and inspect the matching target before reuse.
- Bypass RTK filtering for parsed or equality-checked safety probes while preserving their exit status, and recognize a registered target by an exact target-path line in raw `gh qwt list` output rather than requiring that query to return only one line.
- Whenever the source and target differ, compare the recorded source commit with a tracking branch that belongs to the resolved repository, a matching remote branch, or the selected base, even when the source is dirty. Ahead or diverged source history requires an explicit publish, transfer-to-target, or omit decision; work does not continue in an ordinary source checkout.
- If the source and target differ and either has uncommitted changes, migrate them deliberately with verification or stop to ask how to proceed instead of abandoning or mixing them. Provision a target only when it is missing, and specify the repository explicitly with `get` or `add --repo`.
- Resolve the full GitHub `host/owner/repo` identity, verify an existing qwt repository's canonical `origin` before reuse, and pass the host explicitly when provisioning. This prevents the host-less qwt path layout from mixing repositories on different GitHub hosts.
- Fetch and compare the target before work. Fast-forward only a clean target that is behind, stop on a dirty behind target, and require an explicit choice for ahead, diverged, or local-only target history. Treat a previously tracked branch whose remote disappeared as deleted rather than automatically recreating it as new. Continue from the existing target counterpart of the recorded source-relative directory only after its physical path is verified inside the target worktree.
- When `/pr create` is invoked → use the `pr-create` skill
- When `/pr fix` is invoked → use the `pr-fix` skill
- When `/pr merge` is invoked → use the `pr-merge` skill

The general worktree setup does not run before these PR mappings. Each PR skill selects its own target, and `pr-create` first records the state of the checkout where it was invoked so it can migrate dirty changes safely. As a result, even when you use the built-in `/pr` subcommand, it behaves according to the procedure defined in the skills.

> [!NOTE]
> This integration works through Copilot instruction loading and is not a completely deterministic binding. If you want to ensure the skill is used, invoke it directly with `/pr-create`, `/pr-fix`, or `/pr-merge`.

## Alias setup (recommended)

Add the following to `.zshrc` or `.bashrc`:

```bash
alias pr-create='f() { copilot --model ${COPILOT_MODEL:-claude-sonnet-4.6} -p "/pr-create skill $*"; }; f'
alias pr-fix='f() { copilot --model ${COPILOT_MODEL:-claude-sonnet-4.6} -p "/pr-fix skill $*"; }; f'
alias pr-merge='f() { copilot --model ${COPILOT_MODEL:-claude-sonnet-4.6} -p "/pr-merge skill $*"; }; f'
```

Usage:

```bash
pr-create
pr-fix PR #42
pr-merge 42
```
