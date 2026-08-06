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

## Herdr-dependent skills

A skill that controls Herdr must work only from a Herdr-managed caller pane.

1. Check `HERDR_ENV=1` and that `herdr` is available in `PATH` before issuing
   a control command. If either check fails, do not inspect or control the
   focused Herdr session; define a provider-independent fallback instead.
2. Treat the installed `herdr` binary as the syntax authority. Check
   `herdr --help` and the relevant command group before relying on a command
   whose options may vary by version.
3. Target the caller with `--current` or its explicit pane ID, use IDs returned
   by Herdr's JSON responses, and use `--no-focus` for background work.
   Never depend on the UI-focused pane or derive IDs from sidebar order.
4. Close only panes and tabs created by the skill. If a deployment is blocked,
   fails, or cannot be read, leave its created resources available for
   inspection and report their IDs.
5. For a Copilot child, require a nonempty parent
   `COPILOT_GITHUB_TOKEN`. Load it through a mode-700 temporary Zsh bootstrap,
   pass only non-secret bootstrap and original `ZDOTDIR` paths through Herdr's
   `--env` option, explicitly source the original `.zshenv`, and remove the
   credential files after every child shell is initialized. Never put the
   token in command arguments, output, or prompts. If it is unavailable or the
   shell is not Zsh, use the skill's fallback instead.

## Repository-dependent automation

When a skill invokes an optional GitHub repository feature, query the live
state for the canonical host, repository, and affected branch before invoking
it. Do not infer availability from a checked-in settings file because
organization rules and live repository settings can also apply.

- Distinguish a successful query that reports a disabled feature from an API,
  permission, or network failure. Skip the feature only in the first case and
  stop with a clear error in the second.
- Prefer GitHub's computed PR state, such as `reviewDecision`, when deciding
  whether a workflow requirement has already been satisfied or does not apply.
- Include optional-feature decisions in the skill output so the user can tell
  whether an action ran or was deliberately skipped.

## Checkout-based Pull Request skills

Shared PR skills operate in the Git checkout where the user invokes them. The
checkout may be an ordinary clone, a gh-qw main worktree, or a linked
worktree. Do not create a `gh-qw`, Git, or other worktree for a PR workflow.

- `pr-create` can create a new feature branch in the invoking checkout only
  when its default-branch `HEAD` exactly matches the remote default branch.
  It preserves intended staged, unstaged, and non-ignored untracked changes
  while creating that branch. Stop if the default branch is ahead, behind, or
  diverged instead of pulling, rebasing, or resetting it.
- `pr-fix` and `pr-merge` require the invoking checkout to be clean, on the
  exact PR head branch, and pointed at the head repository. For a fork, require
  a PR URL or explicit base repository and report the canonical fork URL and
  branch when the caller must prepare another checkout.
- Resolve and verify the canonical GitHub identity before API or Git
  operations. Re-check the current branch, working state, and remote head
  before commits, pushes, and merges, particularly after polling waits.
- Do not automatically switch branches for a fix or merge. A direct checkout
  can host only one active PR branch, so concurrent work requires separate
  checkouts, such as linked worktrees or ordinary clones.
- Do not reuse a non-default branch that already has an open, closed, or
  merged PR. Do not silently discard changes, force-push, or use destructive
  recovery.
- After a merge, leave the checked-out local branch in place. A
  lease-protected remote head deletion is allowed only after verifying that the
  remote ref still equals the merged PR head SHA.

This restriction belongs in the skill procedure and constraints. Do not add a
global shell wrapper that changes ordinary interactive Git behavior. See
[ADR 0021](./99-adr/0021-pr-skills-invoking-checkout.md) and
[ADR 0027](./99-adr/0027-gh-qw.md) for the rationale.

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
