# Skill Development

This is a guide for creating or modifying custom Agent Skills that work with
GitHub Copilot, Codex, and Claude Code.

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

Run `bash install.sh` to create the per-skill links, then explicitly invoke the
skill in each agent you support: `/skill-name` in GitHub Copilot,
`$skill-name` in Codex, and `/skill-name` in Claude Code.

If you see a loading error, check whether the `name` and `description` in the frontmatter are correct.

## Writing Rules

| Rule                      | Reason                                                      |
| ------------------------- | ----------------------------------------------------------- |
| Write in English          | To keep both the body text and `description` in English     |
| Write concrete steps      | Ambiguity makes the agent hesitate when deciding what to do |
| State constraints clearly | Prevents infinite loops and destructive operations          |
| Define the output         | Clarifies what the user can expect                          |

## Portability Rules

- Put trigger conditions in the frontmatter `description` instead of relying
  on one product's command syntax.
- Refer to another skill by name, for example “use the `pr-fix` skill”. Do not
  encode `/pr-fix`, `$pr-fix`, or another host-specific invocation in the
  canonical procedure.
- Describe optional helpers by capability. If a host-specific review subagent
  is unavailable, define a provider-independent fallback review pass.
- Keep hooks, manifests, permission schemas, and product settings outside the
  shared skill. Those files stay in vendor-specific directories.
- Test explicit invocation in all supported agents when a change affects
  discovery, inputs, or cross-skill delegation.

## Branch-workspace skills

When a PR skill needs a branch workspace, use the repository's
[`gh-qwt`](../reference/gh-qwt.md) workflow instead of changing the branch of
the invoking checkout.

- Resolve the target worktree with `gh qwt path` and name that path explicitly
  in subsequent Git commands.
- Require raw `gh qwt list --exact --full-path` output to contain each
  calculated worktree path byte-for-byte before reuse and after the `get` or
  `add` that creates it. For a new feature branch, verify the default worktree
  after bootstrap `get` and the feature target after `add`. Treat an occupied
  unregistered path as a collision.
- Treat the GitHub host as part of repository identity even though qwt omits it
  from the path. Resolve the canonical remote identity, compare it with the
  existing bare `origin` before any operation, pass `--host` when provisioning,
  and verify the new repository before use. Stop on a collision instead of
  changing `origin`.
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

- 1 skill = 1 directory
- Directory name = skill name (kebab-case)
- Place the required definition at `dotfiles/skills/<skill-name>/SKILL.md`
- You may also place additional files (such as templates) in the same directory

## Installation

`install_map.json` declares `~/.agents/skills/` and `~/.claude/skills/` as
`skill_targets`. Running `install.sh` links the new skill directory into each
target without replacing the target itself. GitHub Copilot and Codex discover
the first target; Claude Code discovers the second.

GitHub Copilot checks `~/.copilot/skills/` before `~/.agents/skills/` for a
duplicate name. When testing a shared skill, remove or rename any same-named
entry in that higher-priority personal root so the canonical link is the one
being exercised.

## Testing Tips

- After writing a skill, explicitly invoke it in GitHub Copilot, Codex, and Claude Code to confirm discovery and behavior
- If the agent does not follow the steps as intended, make the step descriptions more specific
- Stability improves if you define failure behavior in the `Constraints` section, such as retry counts and stop conditions
