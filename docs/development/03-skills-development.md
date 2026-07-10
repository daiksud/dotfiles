# Skill Development

This is a guide for creating or modifying Copilot CLI custom skills.

## Create a New Skill

### 1. Create the directory and file

```bash
mkdir dotfiles/skills/<skill-name>
touch dotfiles/skills/<skill-name>/SKILL.md
```

### 2. Write `SKILL.md`

```markdown
---
description: Skill description (one line, in English)
name: skill-name
---

# skill-name

## Overview

What the skill does and why it exists.

## When to Use

- Trigger phrases or conditions

## How to Use

### Step 1: ...

### Step 2: ...

## Output

What the user sees when the skill completes.

## Constraints

- Limitations and failure behavior
```

### 3. Verify it works

If the symbolic link is already set up, the skill is available as soon as you create it:

```bash
copilot -p "/skill-name"
```

If you see a loading error, check whether the `name` and `description` in the frontmatter are correct.

## Writing Rules

| Rule                      | Reason                                                      |
| ------------------------- | ----------------------------------------------------------- |
| Write in English          | To keep both the body text and `description` in English     |
| Write concrete steps      | Ambiguity makes the agent hesitate when deciding what to do |
| State constraints clearly | Prevents infinite loops and destructive operations          |
| Define the output         | Clarifies what the user can expect                          |

## Branch-workspace skills

When a PR skill needs a branch workspace, use the repository's
[`gh-qwt`](../reference/gh-qwt.md) workflow instead of changing the branch of
the invoking checkout.

- Resolve the target worktree with `gh qwt path` and name that path explicitly
  in subsequent Git commands.
- Provision a missing repository with `gh qwt get`; provision a missing branch
  worktree with `gh qwt add`. Refresh `origin` in an existing qwt repository
  before `add`, because `add` uses cached remote refs. Before editing a reused
  target, require it to be clean and fast-forward it only when safe.
- State that `git switch`, `git checkout`, ordinary `git worktree`, and
  normal-clone fallbacks are prohibited for the skill.
- Define safe behavior for a dirty source, missing remote branch, path
  collision, deleted fork, and a worktree that cannot be removed. Preserve
  recoverable state and stop rather than using destructive recovery commands.
- If cleanup needs an explicit `owner/repo/branch` argument, run
  `gh qwt remove` outside a qwt repository, such as from `gh qwt root`.

The restriction belongs in the skill procedure and constraints. Do not add a
global shell wrapper that blocks ordinary interactive branch operations unless
that broader behavior is explicitly required.

## File Placement

```
dotfiles/skills/
└── <skill-name>/
    └── SKILL.md       # Required: skill definition file
```

- 1 skill = 1 directory
- Directory name = skill name (kebab-case)
- You may also place additional files (such as templates) in the same directory

## Installation

Because `"skills": "~/.copilot/skills"` is already registered in `install_map.json`, running `install.sh` creates the symbolic link. If the link already exists, the new skill is recognized without any additional action.

## Testing Tips

- After writing a skill, actually invoke it with `copilot -p "/skill-name"` to confirm it works
- If the agent does not follow the steps as intended, make the step descriptions more specific
- Stability improves if you define failure behavior in the `Constraints` section, such as retry counts and stop conditions
