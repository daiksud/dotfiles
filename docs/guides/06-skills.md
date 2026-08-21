# Using skills

This is a guide for using the same custom Agent Skills with GitHub Copilot,
Codex, and Claude Code.

## Prerequisites

- dotfiles are already installed (`install.sh` has been run)
- At least one supported coding agent is installed

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
> `pr-create`, `pr-fix`, or `pr-merge` entry there overrides
> the shared version. Remove or rename that conflicting entry when you want
> Copilot to use the canonical skill installed under `~/.agents/skills/`. See
> GitHub's
> [skill location priority](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#skills-reference).

## Invoke a skill

Start an interactive session and use the syntax for that agent:

| Agent | Explicit invocation |
| ----- | ------------------- |
| GitHub Copilot | `/pr-create` |
| Codex | `$pr-create` |
| Claude Code | `/pr-create` |

Use the corresponding name for any listed skill. Natural-language requests can
also trigger a skill through its frontmatter description, but an explicit
invocation is the most predictable choice.

## Available skills

| Skill | What it does |
| ----------- | ----------------------------------------------------------------------------------------- |
| `pr-create` | Automatically creates a draft PR from the current changes |
| `pr-fix` | Fixes CI errors, handles reviews, and resolves merge conflicts for the specified PR |
| `pr-merge` | Loops review and CI checks, then squash merges one PR, an ordered list, or all open same-repository PRs |

When `install.sh` is re-run, it removes stale symbolic links to canonical skill
directories whose `SKILL.md` no longer exists. Real directories and links to
other sources are preserved.

## How PR skills use the current checkout

The PR skills operate in the Git checkout where you invoke the agent. It may be
an ordinary clone, a gh-qw main worktree, or a linked worktree. The skills
do not create or use a `gh-qw`, Git, or other worktree.

- `pr-create` creates a feature branch in the current checkout when the
  default branch's `HEAD` exactly matches its remote. It keeps staged,
  unstaged, and non-ignored untracked changes in place. A default branch that
  is ahead, behind, or diverged stops instead of being pulled, rebased, or
  reset automatically.
- When invoked from a non-default branch, `pr-create` stops if that branch
  already has an open, closed, or merged PR. Create a new branch rather than
  reusing a branch left checked out after a squash merge.
- `pr-fix` and single-PR `pr-merge` require a clean checkout of the exact PR
  head branch and repository. For a fork PR, prepare a checkout of the fork
  on its head branch before invoking the skill.
- Batch `pr-merge` requires a clean checkout of the target base repository. It
  switches only between verified same-repository head branches and does not
  process fork PRs.
- For numeric inputs, the host-qualified base repository is optional and
  defaults to the current checkout's canonical `origin`.
- Before commits, pushes, and merges, the skills re-check the branch, working
  state, remote head, and expected PR SHA. They stop if another actor changed
  the checkout.
- Single-PR `pr-merge` leaves the local head branch checked out after a
  successful merge. A batch returns to its starting branch and keeps every
  processed local branch. Both modes delete a matching remote head branch only
  after verifying its SHA.
- Batch PRs run sequentially in one checkout. Use separate checkouts, such as
  linked worktrees or ordinary clones, for unrelated concurrent work.

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
3. Creates a feature branch in the current checkout when needed and keeps the
   intended uncommitted changes there
4. Stages the intended uncommitted paths, then commits and pushes the feature
   branch from that checkout
5. Creates a draft PR
6. Sets you as the assignee

## Use `pr-fix`

Explicitly invoke `pr-fix` with a PR URL, or a PR number and host-qualified
base repository, for example `github.com/owner/repo #42`. A natural-language
request to fix or make a PR mergeable also selects this skill through the
shared personal instructions.

Before invoking it, prepare a clean checkout of the PR head repository on the
exact head branch. For a fork PR, this must be a checkout of the fork.

### What happens

1. Resolves the PR head repository and verifies the invoking checkout matches
   its head branch
2. Detects and resolves merge conflicts
3. Identifies CI failures from logs and fixes them (repeating until they pass)
4. Checks review comments and applies reasonable fixes (any comment you reply "対応しない" to is left unchanged, and the reason is recorded in the PR body)
5. Performs a local review before pushing
6. Replies to each review comment with what was addressed and resolves the thread
7. Requests Copilot Code Review only when the PR base branch enables it

If GitHub reports that Copilot Code Review is disabled, the skill finishes the
feedback workflow without requesting it. If the live rules cannot be queried,
the skill stops instead of guessing whether a review should run.

You can also specify `ci`, `feedback`, or `conflicts` before the PR number to
limit the run to CI failures, review comments, or conflicts respectively.

## Use `pr-merge`

Explicitly invoke `pr-merge` with one of these forms:

```text
pr-merge <PR_URL>
pr-merge <PR_NUMBER> [<base-repository>]
pr-merge <PR_NUMBER> <PR_NUMBER> ... [<base-repository>]
pr-merge all [<base-repository>]
```

For numeric inputs, the optional base repository defaults to the current
checkout's canonical `origin`. A single PR URL remains the compatibility form
for fork PRs. A natural-language request to merge a review-clean PR also
selects this skill through the shared personal instructions.

### What happens

1. In single-PR mode, verifies the exact head checkout. In batch mode, saves
   the starting branch, snapshots the requested PRs, and switches only between
   clean same-repository head branches.
2. Runs `pr-fix` and, when the base branch enables Copilot Code Review, requests
   reviews until there are no unresolved findings (up to 10 attempts per PR).
3. Takes each PR out of Draft and asks GitHub whether approval is required.
4. Reuses an existing valid approval or, only when review is required, applies
   the `self approval` label once and waits up to 3 minutes for the existing
   automation. Approval state is retained only while GitHub reports it as
   valid, and never carries across PRs.
5. Waits for CI to go green, going back to the retry loop if a merge conflict
   or CI failure appears.
6. Squash merges each verified PR, safely deletes only an unchanged matching
   remote head, and records cleanup warnings.
7. For a batch, continues after a clean per-PR failure, stops rather than
   discarding dirty or conflicted state, and returns to the starting branch.

`all` includes every open PR, including Drafts, snapshots them at invocation
time, and processes them in ascending PR-number order. Fork PRs are reported as
skipped because batch mode requires the target repository's own head branches.

An unavailable base-branch rules query is reported as a failure; it is not
treated as a disabled feature.

> [!IMPORTANT]
> When review is required, `pr-merge` waits for an existing automation that
> approves PRs labeled `self approval`; it does not create that automation or
> label. Repositories where GitHub reports that review is unnecessary skip
> both the label and approval wait.

## Shared instructions

Personal instructions have one canonical source,
`dotfiles/agent-instructions.md`. `install.sh` links it to the locations loaded
by GitHub Copilot, Codex, and Claude Code:

- `~/.copilot/copilot-instructions.md`
- `~/.codex/AGENTS.md`
- `~/.claude/CLAUDE.md`

The file maps PR creation, fixing, and merging requests to the corresponding
shared skills. The file requires a rationale in every agent-created
commit: non-trivial commits record their context, decision, considerations,
and impact. The detailed procedures remain in the skills, so all three agents
execute the same workflow instead of maintaining product-specific copies.

Root `AGENTS.md` is the canonical repository instruction file. Claude imports
it through `CLAUDE.md`. Copilot Code Review reads
`.github/copilot-instructions.md` directly and does not import `AGENTS.md`, so
that file is a checked-in exact mirror; `tests/agent_configuration.bats`
prevents it from drifting.

GitHub Actions rules are canonical in `.github/workflows/AGENTS.md`. Claude
imports that file from its path-scoped rule, while the body of the
path-specific Copilot file is an inline exact mirror after its required
frontmatter. When changing either canonical file, update its Copilot mirror
and run `bats tests/agent_configuration.bats`.

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
pr-fix github.com/owner/repo 42
pr-merge github.com/owner/repo 42
```
