# Using skills

This is a guide for using the same custom Agent Skills with GitHub Copilot,
Codex, and Claude Code.

## Prerequisites

- dotfiles are already installed (`install.sh` has been run)
- At least one supported coding agent is installed
- The `gh-qwt` GitHub CLI extension is available (it is installed by the
  dotfiles setup)

## Where skills are installed

`dotfiles/skills/` is the canonical source. The installer creates one link per
skill instead of linking the entire directory:

| Agents | Discovery root |
| ------ | -------------- |
| GitHub Copilot and Codex | `~/.agents/skills/` |
| Claude Code | `~/.claude/skills/` |

Creating missing roots as real directories and never replacing an existing
root preserves unrelated built-in and independently installed skills. See
[`install_map.json`](../reference/install-map.md) for the mapping format.

> [!WARNING]
> GitHub Copilot gives `~/.copilot/skills/` higher priority than
> `~/.agents/skills/` when duplicate skill names exist. The installer preserves
> a real `~/.copilot/skills/` directory or a link to another source, so a stale
> `pr-create`, `pr-fix`, or `pr-merge` entry there overrides the shared version.
> Remove or rename that conflicting entry when you want Copilot to use the
> canonical skill installed under `~/.agents/skills/`. See GitHub's
> [skill location priority](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#skills-reference).

## Invoke a skill

Start an interactive session and use the syntax for that agent:

| Agent | Explicit invocation |
| ----- | ------------------- |
| GitHub Copilot | `/pr-create` |
| Codex | `$pr-create` |
| Claude Code | `/pr-create` |

Use the corresponding name for `pr-fix` or `pr-merge`. Natural-language
requests can also trigger a skill through its frontmatter description, but an
explicit invocation is the most predictable choice.

## Available skills

| Skill       | What it does                                                                              |
| ----------- | ----------------------------------------------------------------------------------------- |
| `pr-create` | Automatically creates a draft PR from the current changes                                 |
| `pr-fix`    | Fixes CI errors, handles reviews, and resolves merge conflicts for the specified PR       |
| `pr-merge`  | Loops `pr-fix` and Copilot Code Review to zero findings, then approves, waits for CI, and squash merges one or more PRs |

## How PR skills use worktrees

The PR skills do not switch the branch of the checkout where you invoked the
agent. They create or reuse a [`gh-qwt`](../reference/gh-qwt.md) worktree
for the feature or PR head branch, then perform Git operations only in that
path.

- On a first use, the skill can provision the repository under your qwt root.
- The skill verifies the full GitHub host and repository identity before using
  a qwt path. Repositories with the same `owner/repo` on different GitHub hosts
  need separate qwt roots because the on-disk path omits the host.
- `pr-create` safely transfers staged, unstaged, and non-ignored untracked
  changes from a default-branch worktree into the new feature worktree.
- If the default branch has local commits, the skill stops instead of resetting,
  rebasing, or pushing that branch automatically.
- A branch name that collides with another qwt path, such as `feat` and
  `feat/login`, stops with an error rather than falling back to a branch
  switch.
- A directory at the calculated path is used only when qwt reports that exact
  absolute path as a registered worktree; stale or unrelated occupied paths
  stop as collisions.
- `pr-fix` works in the PR head worktree, including a fork's repository when
  applicable. `pr-merge` removes the clean worktree after a successful merge.

> [!IMPORTANT]
> PR skills intentionally do not use `git switch`, `git checkout`, ordinary
> `git worktree`, or a normal-clone fallback. This policy applies to the
> skills; it does not change your normal interactive Git commands.

## Use `pr-create`

With the intended changes already committed or present as staged, unstaged,
or non-ignored untracked files, explicitly invoke `pr-create` using the syntax
for your agent.

You can add context after the invocation, such as “Refactor authentication
logic, related to #42”. A natural-language request to create a PR also selects
this skill through the shared personal instructions.

### What happens

1. Checks for a corresponding Task (Issue) and suggests creating one if it does not exist
2. Reads the committed and uncommitted state, confirms the intended scope, and
   comes up with a commit message
3. Creates or reuses an isolated qwt feature worktree and safely moves
   uncommitted changes there when needed
4. Stages the intended uncommitted paths, then commits and pushes the feature
   branch from that worktree
5. Creates a draft PR
6. Sets you as the assignee

## Use `pr-fix`

Explicitly invoke `pr-fix` and include the PR number, for example `PR #42`.
A natural-language request to fix or make a PR mergeable also selects this
skill through the shared personal instructions.

### What happens

1. Resolves the PR head repository and creates or reuses its qwt worktree
2. Detects and resolves merge conflicts
3. Identifies CI failures from logs and fixes them (repeating until they pass)
4. Checks review comments and applies reasonable fixes (any comment you reply "対応しない" to is left unchanged, and the reason is recorded in the PR body)
5. Performs a local review before pushing
6. Replies to each review comment with what was addressed and resolves the thread

You can also specify `ci`, `feedback`, or `conflicts` before the PR number to
limit the run to CI failures, review comments, or conflicts respectively.

## Use `pr-merge`

Explicitly invoke `pr-merge` followed by a PR number. Multiple PRs can be given
at once, separated by spaces; they are processed one at a time. A
natural-language request to merge a review-clean PR also selects this skill
through the shared personal instructions.

### What happens

For each PR number given:

1. Runs `pr-fix` and requests a review from Copilot Code Review, repeating until there are no unresolved findings (up to 10 attempts)
2. Takes the PR out of Draft, reuses an existing valid approval, or applies the
   `self approval` label once
3. Waits for the repository's existing self-approval automation to approve the
   PR (up to 3 minutes from that one request); the approval is retained across
   CI or conflict retries while it remains valid
4. Waits for CI to go green, going back to step 1 if a merge conflict or a CI failure shows up
5. Squash merges the PR once everything is green, then removes its qwt
   worktree and branch workspace

If a PR cannot be brought to a mergeable state, it is skipped (with the reason recorded) so the rest of the batch keeps going, and a summary is reported at the end.

> [!IMPORTANT]
> `pr-merge` waits for an existing automation that approves PRs labeled `self approval` — it does not create that automation. It also expects the `self approval` label to already exist in the repository.

## Shared instructions

Personal instructions have one canonical source,
`dotfiles/agent-instructions.md`. `install.sh` links it to the locations loaded
by GitHub Copilot, Codex, and Claude Code:

- `~/.copilot/copilot-instructions.md`
- `~/.codex/AGENTS.md`
- `~/.claude/CLAUDE.md`

The file defines the general `gh-qwt` safety workflow and maps PR creation,
fixing, and merging requests to the corresponding shared skills. The detailed
procedures remain in the skills, so all three agents execute the same workflow
instead of maintaining product-specific copies.

Repository instructions follow the same canonical-plus-adapter pattern. Root
`AGENTS.md` is canonical; `.github/copilot-instructions.md` and `CLAUDE.md` are
thin adapters for tools that require their own filename. GitHub Actions rules
are scoped by canonical `.github/workflows/AGENTS.md`, with thin Copilot and
Claude adapters at their product-specific paths.

Hooks, manifests, permissions, and other product-specific configuration do not
share a schema. They remain under their vendor-specific directories and can
refer to the shared instructions or skills where appropriate.

## Copilot CLI aliases (optional)

Add the following to `.zshrc` or `.bashrc`:

```bash
alias pr-create='f() { copilot -p "/pr-create skill $*"; }; f'
alias pr-fix='f() { copilot -p "/pr-fix skill $*"; }; f'
alias pr-merge='f() { copilot -p "/pr-merge skill $*"; }; f'
```

Usage:

```bash
pr-create
pr-fix PR #42
pr-merge 42
```
