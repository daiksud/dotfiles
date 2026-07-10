# Copilot Skills

This is the specification reference for custom skills.

## Skill list

| Skill       | Description                                                                                                                                  |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `pr-create` | Check the corresponding Task, understand the changes, and create a draft PR with an appropriate commit message and description               |
| `pr-fix`    | Fix CI errors and handle review comments to bring the PR into a mergeable state                                                              |
| `pr-merge`  | Loop `pr-fix` and Copilot Code Review until there are no findings, then take the PR ready, label it, wait for approval and CI, and squash merge |

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

## Detailed specification for `pr-create`

### Workflow

1. Check the corresponding Task (Issue) (if it cannot be inferred, ask the user to confirm; if there is none, encourage them to create one)
2. Understand the changes with `git diff` (also refer to the Issue description and comments)
3. Commit using the Conventional Commits format
4. Push to the feature branch
5. Create the PR description (write a readable, visually clear body that fully leverages GFM features such as tables, alerts, Mermaid, and emoji), then create a draft PR with `gh pr create --draft`
6. Set the invoking user as the Assignee
7. Finally, update the corresponding Task description to match the final changes (move the original plan to a comment)

### Input

- Staged files, or already committed diffs
- Optional: reason for the change, related Issue number

### Output

- URL of the created draft PR

## Detailed specification for `pr-fix`

### Workflow

1. Check the CI status of the specified PR
2. If there are CI failures, analyze the logs and repeat fixes (up to 3 times)
3. Retrieve all review comments and judge the validity of each one
4. Fix valid comments and skip invalid ones; for comments the user replied "対応しない" (will not address) to, record in the PR body that they will not be addressed along with the reason
5. Before committing and pushing, run a local review with the `code-review` sub-agent
6. After pushing, reply to each review comment with how it was addressed

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
6. Once CI is green and there are no conflicts, squash merge (`gh pr merge --squash --delete-branch`)

Multiple PR numbers are processed one at a time; a PR that fails or times out is skipped (recorded) so the rest of the batch still runs.

> [!NOTE]
> `pr-merge` assumes an automation that approves PRs labeled `self approval` already exists (outside this skill's scope) and only waits for its result. It also assumes the `self approval` label already exists in the repository; it does not create the label.

### Input

- One or more PR numbers (required)

### Output

- The merged PR's URL for each successfully merged PR
- The failure reason (which step, and why) for any PR that could not be merged
- A final summary across all given PR numbers
