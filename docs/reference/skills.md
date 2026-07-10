# Copilot Skills

This is the specification reference for custom skills.

## Skill list

| Skill       | Description                                                                                                                                  |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `pr-create` | Create a draft PR from an isolated `gh-qwt` feature worktree, with an appropriate commit message and description                            |
| `pr-fix`    | Use the PR head's `gh-qwt` worktree to fix CI errors and handle review comments                                                             |
| `pr-merge`  | Loop `pr-fix` and Copilot Code Review until there are no findings, then merge and clean up the qwt branch workspace                         |

## Installation destination

When `install.sh` runs, `dotfiles/skills/` is symlinked to `~/.copilot/skills/`.

## Directory structure

```
dotfiles/skills/
├── pr-create/
│   └── SKILL.md
├── pr-fix/
│   └── SKILL.md
└── pr-merge/
    └── SKILL.md
```

> [!NOTE]
> This repository has no vendored skills at the moment. A skill installed directly from an upstream repository with `gh skill install <repo> <skill>` (fetching the skill's directory, including `SKILL.md` and any accompanying files, verbatim) would carry extra frontmatter fields such as `compatibility`, `license`, and a `metadata` provenance block, and should be treated as synced content — re-run `gh skill install` to update it instead of hand-editing it to match the spec below.

## `SKILL.md` format specification

### Structure

Frontmatter is required. The section structure of the body can be freely defined according to the nature of the skill.

**Example of a simple skill (`pr-create` style):**

```markdown
---
description: Skill description (1 line, in English)
name: Skill name
---

# Skill name

## Overview

(What the skill does)

## When to use

(What kind of situations it is used in)

## Procedure

### Step 1: ...

### Step 2: ...

## Output

(What the skill outputs)
```

**Example of a skill with mode branching (`pr-fix` style):**

```markdown
---
description: Skill description (1 line, in English)
name: Skill name
---

# Skill name

## Usage

(How to invoke it and an explanation of each mode)

## Modes

### mode-a — ...

### mode-b — ...

## Common steps

(Processing performed in all modes)

## Constraints

(Constraints)
```

### Frontmatter (required)

| Field         | Type   | Description                                     |
| ------------- | ------ | ----------------------------------------------- |
| `name`        | string | Skill identifier. Must match the directory name |
| `description` | string | Skill summary. Displayed in the CLI skill list  |

### Language used in the body

- Write the frontmatter `description` in **English** (used in the CLI skill list display)
- Write the body in **English**

### Section guidelines

| Section              | Required    | Description                                          |
| -------------------- | ----------- | ---------------------------------------------------- |
| Overview or Usage    | ✅          | Explain the purpose of the skill or how to invoke it |
| Procedure or Modes   | ✅          | Step-by-step or mode-specific operating procedure    |
| Constraints          | Recommended | Constraints and behavior on failure                  |
| Output               | Recommended | What is shown to the user when the skill finishes    |
| Hints for developers | Optional    | Example alias configuration, etc.                    |

## PR workspace policy

The three PR skills use [`gh-qwt`](./gh-qwt.md) as their only
branch-workspace mechanism. A branch is represented by its own worktree, not
by changing the branch of the invoking checkout.

- The skills resolve a target with `gh qwt path` and run repository commands
  against that absolute path.
- A missing qwt repository is provisioned with `gh qwt get`. A missing branch
  worktree in an existing qwt repository is created with `gh qwt add`.
  `get --branch` is used only for an existing remote branch; creating a new
  branch first requires `get` for the default branch, followed by `add`.
- Before `add` runs in an existing qwt repository, the skills refresh
  `origin --prune` from the qwt repository root so cached refs cannot turn a
  just-pushed branch into a mistakenly new branch.
- Before a PR skill edits a reused target, it requires a clean worktree and
  either fast-forwards it to its remote head or stops on an ahead/diverged
  branch. It never silently overwrites an existing worktree.
- The skill procedures must not use `git switch`, `git checkout`, ordinary
  `git worktree`, or a normal-clone fallback.
- If qwt cannot safely create a worktree, such as a slash-prefix path
  collision, the skill reports the error and stops. It does not change the
  branch of another checkout as a workaround.
- This restriction applies to PR skills only. Interactive shell Git commands
  remain unchanged.

`pr-create` preserves uncommitted source changes through a named stash and
verification before it clears the source. When the source is a normal clone,
the stash is transferred as a temporary Git bundle so staged, unstaged, and
non-ignored untracked changes retain their state in the qwt target. A default
branch with local commits is intentionally not reset, rebased, or pushed by
the skill; it stops and asks for explicit direction instead.

## Detailed specification for `pr-create`

### Workflow

1. Check the corresponding Task (Issue) (if it cannot be inferred, ask the user to confirm; if there is none, encourage them to create one)
2. Understand the source changes with `git diff` and the Issue description and comments
3. Resolve or create the feature branch's qwt worktree, migrating uncommitted changes only through the verified preservation procedure
4. Commit from the target worktree using the Conventional Commits format
5. Push the target branch
6. Create the PR description (write a readable, visually clear body that fully leverages GFM features such as tables, alerts, Mermaid, and emoji), then create a draft PR with `gh pr create --draft`
7. Set the invoking user as the Assignee
8. Finally, update the corresponding Task description to match the final changes (move the original plan to a comment)

### Input

- Staged files, or already committed diffs
- Optional: reason for the change, related Issue number

### Output

- URL of the created draft PR

## Detailed specification for `pr-fix`

### Workflow

1. Resolve the base repository and the PR head repository / branch, then create or reuse the head qwt worktree
2. Check the CI status of the specified PR
3. If there are CI failures, analyze the logs and repeat fixes (up to 3 times)
4. Retrieve all review comments and judge the validity of each one
5. Fix valid comments and skip invalid ones; for comments the user replied "対応しない" (will not address) to, record in the PR body that they will not be addressed along with the reason
6. Before committing and pushing, run a local review with the `code-review` sub-agent
7. After pushing, reply to each review comment with how it was addressed

The PR API remains scoped to the base repository. Git changes and pushes occur
only in the head worktree. For a fork PR, the head repository is used as the
qwt target; a deleted fork or missing push access stops the skill instead of
creating a substitute branch in the base repository.

### Input

- PR number (required)

### Output

- Replies to each review comment
- Error report if CI still does not pass

## Detailed specification for `pr-merge`

### Workflow

`pr-merge` runs a single retry loop (up to 10 iterations) per PR:

1. Run `/pr-fix all <PR>`, request a review from Copilot Code Review (same GraphQL mutation as `pr-fix`), and wait for it to complete
2. Count the unresolved findings left by Copilot Code Review (paginated `reviewThreads`, filtered to `copilot-pull-request-reviewer`); if any remain, go back to step 1
3. Mark the PR ready for review (`gh pr ready`) and apply the `self approval` label
4. Wait for the pre-existing self-approval automation to approve the PR (short 3-minute timeout, since a miss usually means the automation is not configured)
5. Wait for CI to go green and re-check mergeability; a merge conflict or a CI failure sends control back to step 1, since `/pr-fix all` can fix both
6. Once CI is green and there are no conflicts, verify that the qwt worktree
   is clean and still matches the PR head, squash merge with the checked head
   SHA, then remove the qwt worktree and local branch with `gh qwt remove
   --delete-branch`

After the qwt cleanup, `pr-merge` deletes the head remote branch directly from
its repository only when it still equals the verified PR head SHA. The
lease-protected deletion works for both same-repository and fork PRs, while
avoiding the branch checkout that GitHub CLI can otherwise perform during
local branch deletion. The explicit `gh qwt remove owner/repo/branch` command
runs from qwt root so its argument cannot be mistaken for a branch name.

Multiple PR numbers are processed one at a time; a PR that fails or times out is skipped (recorded) so the rest of the batch still runs.

> [!NOTE]
> `pr-merge` assumes an automation that approves PRs labeled `self approval` already exists (outside this skill's scope) and only waits for its result. It also assumes the `self approval` label already exists in the repository; it does not create the label.

### Input

- One or more PR numbers (required)

### Output

- The merged PR's URL for each successfully merged PR
- The failure reason (which step, and why) for any PR that could not be merged
- A final summary across all given PR numbers
