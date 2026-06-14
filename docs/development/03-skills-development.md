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
description: Skill description (one line, in Japanese)
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

| Rule                        | Reason                                              |
| --------------------------- | --------------------------------------------------- |
| Write in Japanese           | To keep both the body text and `description` in Japanese |
| Write concrete steps        | Ambiguity makes the agent hesitate when deciding what to do |
| State constraints clearly   | Prevents infinite loops and destructive operations  |
| Define the output           | Clarifies what the user can expect                  |

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
