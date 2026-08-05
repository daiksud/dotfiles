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
> `herdr-subagents`, `pr-create`, `pr-fix`, or `pr-merge` entry there overrides
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
| `herdr-subagents` | Runs coding subagents in Herdr panes or tabs and collects their results |
| `pr-create` | Automatically creates a draft PR from the current changes |
| `pr-fix` | Fixes CI errors, handles reviews, and resolves merge conflicts for the specified PR |
| `pr-merge` | Loops enabled Copilot Code Review to zero findings, requests approval only when required, waits for CI, and squash merges one PR |

## Use `herdr-subagents`

Explicitly invoke `herdr-subagents` when you are inside a Herdr-managed pane
and want to deploy one or more coding subagents. The shared personal
instructions select it automatically for subagent deployments from such a
pane.

The skill requires `HERDR_ENV=1` and an available `herdr` CLI. It keeps your
focus in the invoking pane, uses the current tab for one or two agents, and
uses 2x2 new tabs for larger groups. It only closes the resources it created
after every result is captured successfully. If Herdr is unavailable, it
falls back to your agent's native subagent facility and reports why.

When a subagent uses Copilot, the skill requires a nonempty parent
`COPILOT_GITHUB_TOKEN`. It loads the token through a private temporary Zsh
bootstrap, preserves and sources the parent's original Zsh environment, and
passes only non-secret directory paths to Herdr. It removes the bootstrap
after each child shell is initialized. This pins the child to the parent's
Copilot user without exposing the token in command arguments.

## How PR skills use the current checkout

The PR skills operate in the Git checkout where you invoke the agent. It may be
an ordinary clone, a gh-qwt primary checkout, or a linked worktree. The skills
do not create or use a `gh-qwt`, Git, or other worktree.

- `pr-create` creates a feature branch in the current checkout when the
  default branch's `HEAD` exactly matches its remote. It keeps staged,
  unstaged, and non-ignored untracked changes in place. A default branch that
  is ahead, behind, or diverged stops instead of being pulled, rebased, or
  reset automatically.
- If `pr-create` moves a gh-qwt primary checkout off `qwt.defaultbranch`, it
  reports that gh-qwt management commands will reject the repository until you
  restore the pinned branch. Use a linked worktree when you need gh-qwt
  management commands to remain available while working on the PR.
- When invoked from a non-default branch, `pr-create` stops if that branch
  already has an open, closed, or merged PR. Create a new branch rather than
  reusing a branch left checked out after a squash merge.
- `pr-fix` and `pr-merge` require a clean checkout of the exact PR head branch
  and repository. For a fork PR, prepare a checkout of the fork on its
  head branch before invoking the skill.
- For `pr-fix` and `pr-merge`, provide a PR URL or a PR number together with
  its host-qualified base repository. A fork checkout cannot identify the base
  repository from a number alone.
- Before commits, pushes, and merges, the skills re-check the branch, working
  state, remote head, and expected PR SHA. They stop if another actor changed
  the checkout.
- `pr-merge` handles one PR per invocation and leaves the local head branch
  checked out after a successful merge. It can delete the matching remote head
  branch only after verifying its SHA.
- Use separate checkouts, such as linked worktrees or ordinary clones, for
  concurrent PR work.

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

Explicitly invoke `pr-merge` with a PR URL, or a PR number and host-qualified
base repository, from a clean checkout of that PR's head repository and branch.
A natural-language request to merge a review-clean PR also selects this skill
through the shared personal instructions.

### What happens

1. Runs `pr-fix` and, when the base branch enables Copilot Code Review,
   requests reviews until there are no unresolved findings (up to 10 attempts)
2. Takes the PR out of Draft and asks GitHub whether approval is required
3. Reuses an existing valid approval or, only when review is required, applies
   the `self approval` label once and waits up to 3 minutes for the existing
   automation; the approval is retained across CI or conflict retries while
   GitHub continues to report it as valid
4. Waits for CI to go green, going back to step 1 if a merge conflict or a CI failure shows up
5. Squash merges the PR once everything is green, leaves the local branch
   checked out, and safely deletes only an unchanged matching remote head
   branch

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
shared skills. It also routes subagent deployments in Herdr-managed panes to
`herdr-subagents`. The file requires a rationale in every agent-created
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
