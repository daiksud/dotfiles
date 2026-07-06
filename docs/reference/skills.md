# Copilot Skills

This is the specification reference for custom skills.

## Skill list

| Skill       | Description                                                                                                                                  |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `gh-wt`     | Creates, lists, removes CoW-backed git worktrees via the gh-wt extension (installed from upstream via `gh skill install`, not hand-authored) |
| `pr-create` | Check the corresponding Task, understand the changes, and create a draft PR with an appropriate commit message and description               |
| `pr-fix`    | Fix CI errors and handle review comments to bring the PR into a mergeable state                                                              |

## Installation destination

When `install.sh` runs, `dotfiles/skills/` is symlinked to `~/.copilot/skills/`.

## Directory structure

```
dotfiles/skills/
├── gh-wt/
│   ├── SKILL.md
│   └── evals/
│       ├── evals.json
│       └── trigger_queries.json
├── pr-create/
│   └── SKILL.md
└── pr-fix/
    └── SKILL.md
```

## Skills installed via `gh skill install`

Some skills, such as `gh-wt`, are not hand-authored in this repository. They are installed directly from an upstream repository with `gh skill install <repo> <skill>`, which fetches the skill's directory (including `SKILL.md` and any accompanying files) verbatim.

- **Frontmatter**: may include extra fields outside this repo's own spec below, such as `compatibility`, `license`, and a `metadata` block (`github-path`, `github-ref`, `github-repo`, `github-tree-sha`) that record the provenance — source repo, tag, and commit — the content was synced from
- **Language**: the `description` and body follow the upstream author's choice (English is fine) instead of this repo's Japanese convention for hand-authored skills
- **Evals**: an installed skill may ship an `evals/` directory with author-provided test cases (`evals.json`, `trigger_queries.json`) that validate trigger phrases and expected behavior; these are tracked in git as-is, since they are static author-provided content rather than local generated or runtime state

> [!IMPORTANT]
> Do not hand-edit the `SKILL.md` of an installed skill to match this repo's format conventions below. Treat it as vendored/synced content — if it needs an update, re-run `gh skill install` to pull the latest upstream version instead.

For `gh-wt`'s commands and usage, see [gh-wt](./gh-wt.md).

## `SKILL.md` format specification

### Structure

Frontmatter is required. The section structure of the body can be freely defined according to the nature of the skill.

**Example of a simple skill (`pr-create` style):**

```markdown
---
description: Skill description (1 line, in Japanese)
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
description: Skill description (1 line, in Japanese)
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

- Write the frontmatter `description` in **Japanese** (used in the CLI skill list display)
- Write the body in **Japanese**

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
