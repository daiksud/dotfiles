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

If you see a loading error, check whether the `name` and `description` in the
frontmatter are correct.

## Writing Rules

| Rule | Reason |
| --- | --- |
| Write in English | To keep both the body text and `description` in English |
| Write concrete steps | Ambiguity makes the agent hesitate when deciding what to do |
| State constraints clearly | Prevents infinite loops and destructive operations |
| Define the output | Clarifies what the user can expect |

## Portability Rules

- Put trigger conditions in the frontmatter `description` instead of relying
  on one product's command syntax.
- Refer to another skill by its name, for example “use the `pr-fix` skill”. Do
  not encode `/pr-fix`, `$pr-fix`, or another host-specific invocation in the
  canonical procedure.
- Describe optional helpers by capability. If a host-specific review subagent
  is unavailable, define a provider-independent fallback review pass.
- Keep manifests, permission schemas, and product settings outside the shared
  skill. Those files stay in vendor-specific directories.
- Test explicit invocation in all supported agents when a change affects
  discovery, inputs, or cross-skill delegation.
- Keep user-specific policies, such as organization-specific comment prefixes,
  in an untracked local configuration file rather than in shared skill text.

## Repository-dependent automation

When a skill invokes an optional GitHub repository feature, query the live
state for the canonical host, repository, and affected branch before invoking
it. Do not infer availability from a checked-in settings file because
organization rules and live repository settings can also apply.

- Distinguish a successful query that reports a disabled feature from an
  unavailable optional feature. For optional PR review automation, skip the
  feature when GitHub reports that it is unavailable, including plan or
  permission limitations, and report that decision clearly.
- Prefer GitHub's computed PR state, such as `reviewDecision`, when deciding
  whether a workflow requirement has already been satisfied or does not apply.
- Include optional-feature decisions in the skill output so the user can tell
  whether an action ran or was deliberately skipped.

## Checkout-based Pull Request skills

Shared PR skills use the Git checkout where the user invokes them for
repository context. The checkout may be an ordinary clone, a gh-qw main
worktree, or a linked worktree. `pr-create` keeps it as its workspace, while
`pr-fix` and `pr-merge` reuse a verified existing PR-head worktree or create
or reuse one deterministic worktree per PR with the native
`gh pr checkout --worktree` command. The invoking checkout may be the selected
target when it already checks out the PR head branch and passes validation.

- `pr-create` can create a new feature branch in the invoking checkout only
  when its default-branch `HEAD` exactly matches the remote default branch.
  It preserves intended staged, unstaged, and non-ignored untracked changes
  while creating that branch. Stop if the default branch is ahead, behind, or
  diverged instead of pulling, rebasing, or resetting it.
- `pr-fix` and `pr-merge` derive
  `<repository-parent>/.pr-worktrees/<base-host>/<base-owner>/<base-repo>/pr-<PR_NUMBER>`,
  reuse an existing clean worktree for `<head-branch>` when one is registered,
  including the invoking checkout, or check out the PR from its remote
  otherwise. They verify the selected worktree's exact `headRefOid` and push
  destination before editing. A fork uses the same isolated flow; a missing
  fork or unavailable push access stops that PR safely.
- Resolve and verify the canonical GitHub identity before API or Git
  operations. Re-check the current branch, working state, and remote head
  before commits, pushes, and merges, particularly after polling waits.
- Do not automatically switch the invoking checkout to another branch. It may
  be used for PR edits when it is already the verified target branch. Batch
  `pr-merge` processes each PR sequentially in verified worktrees, never
  discards local work, and stops on an unsafe source or target state.
- `pr-create` must not reuse a non-default branch that already has an open,
  closed, or merged PR. Do not silently discard changes, force-push, or use
  destructive recovery.
- After a merge, retain the clean PR worktree and local branch. A
  lease-protected remote head deletion is allowed only after verifying that the
  remote ref still equals the merged PR head SHA.

This worktree contract belongs in the skill procedure and constraints. Do not
add a global shell wrapper that changes ordinary interactive Git behavior. See
[ADR 0021](./99-adr/0021-pr-skills-invoking-checkout.md),
[ADR 0027](./99-adr/0027-gh-qw.md), and
[ADR 0035](./99-adr/0035-pr-skills-dedicated-worktrees.md) for the rationale.

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

- After writing a skill, explicitly invoke it in GitHub Copilot, Codex, and
  Claude Code to confirm discovery and behavior.
- If the agent does not follow the steps as intended, make the step descriptions
  more specific.
- Stability improves if you define failure behavior in the `Constraints`
  section, such as retry counts and stop conditions.
