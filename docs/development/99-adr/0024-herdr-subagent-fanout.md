# ADR 0024: Fan out subagents into Herdr panes

Run each deployed subagent in a visible Herdr pane or tab when the invoking
agent already runs in a Herdr-managed pane.

## Status

Superseded by [ADR 0028](./0028-native-subagent-deployment.md)

## Context

[ADR 0015](./0015-herdr-terminal-multiplexer.md) adopted Herdr because it can
show the state of multiple coding agents and preserve their terminal sessions.
That decision did not define how an orchestrating agent should lay out and
start subagents. As a result, a host can use in-process subagents that are
neither represented in the Herdr layout nor directly controllable by the user.

The personal instructions are shared by GitHub Copilot, Codex, and Claude
Code. A single product's Herdr integration cannot define a portable workflow
for all three. At the same time, placing a full terminal orchestration
procedure in always-loaded personal instructions would make that file large
and harder to maintain.

## Decision

Adopt a two-layer Herdr subagent policy:

- `dotfiles/agent-instructions.md` directs every subagent deployment from a
  Herdr-managed pane to the shared `herdr-subagents` skill. The policy applies
  from the first subagent, not only to larger fan-outs.
- `dotfiles/skills/herdr-subagents/SKILL.md` contains the portable procedure.
  It verifies `HERDR_ENV=1` and an available `herdr` CLI before acting, then
  falls back to the host's native subagent facility with a reported reason
  when Herdr cannot be used.
- One or two subagents use the current tab: the caller remains in the left
  pane, and agents use a right pane or its two vertical cells. Three or four
  subagents use a new 2x2 tab. Larger groups use one new 2x2 tab per four
  agents, with unused final cells left as shells.
- New panes and tabs use `--no-focus`, so the caller retains the user's focus.
  A user-requested agent kind takes priority; otherwise the caller's kind is
  used.
- A Copilot child requires a nonempty parent `COPILOT_GITHUB_TOKEN`. Herdr
  receives only a non-secret `ZDOTDIR` path to a private temporary bootstrap.
  The original Zsh configuration path is also passed so each child can source
  its normal `.zshenv` after loading the token. Those files are then removed,
  which pins the child to the exact parent user without exposing the token in
  process arguments or changing its regular shell environment.
- Prompts are submitted concurrently and waited for collectively. Each prompt
  must be self-contained, and agents may write concurrently only to explicitly
  non-overlapping file scopes.
- Results are collected before cleanup. On complete success, only resources
  created by the run are closed. On failure, timeout, blocked state, agent
  service error, or unreadable result, all created resources remain open for
  inspection.

This follows [ADR 0013](./0013-cross-agent-skills-and-instructions.md): a
small canonical policy dispatches detailed portable behavior to a shared
skill.

## Alternatives Considered

### Put the full procedure in personal instructions

This would make the policy immediately visible, but the layout, lifecycle, and
failure-handling details would bloat always-loaded context and duplicate the
role of a skill. It was rejected in favor of a concise dispatch rule.

### Use only an explicit skill

An explicit skill alone would preserve concise instructions, but subagents
would continue to use host-local mechanisms unless a user remembered to invoke
the skill. It was rejected because the desired behavior is the default inside
Herdr.

### Reuse a product-specific Herdr integration

A vendor-provided integration can be unavailable to another supported coding
agent and may have different lifecycle semantics. It was rejected in favor of
the `herdr` CLI, whose installed binary provides the common syntax authority.

### Create a separate worktree for every subagent

Separate worktrees isolate concurrent edits, but they add checkout setup and
cleanup for read-only or disjoint-file work. They also exceed the requested
terminal-layout policy. The skill instead requires non-overlapping write
scopes and uses worktrees only when the user explicitly asks for them.

### Always create a new tab

This would avoid changing the caller's tab for small fan-outs, but it wastes
layout for one or two agents and conflicts with the requested left-caller
layout. It was rejected in favor of threshold-based placement.

## Consequences

- Users can see and directly interact with every deployed subagent in Herdr.
- One- and two-agent runs temporarily split the caller's tab, but successful
  cleanup restores the created panes without affecting the caller.
- A failed run intentionally leaves its panes and tabs available for diagnosis,
  which may require the user to close them after resolving the issue.
- A partial group still consumes a 2x2 tab with unused shell panes. This keeps
  multi-agent layouts predictable.
- Orchestrators must partition concurrent write scopes carefully; Herdr
  visibility does not make shared-checkout edits safe.
- Copilot children share the parent user's credentials, quotas, and account
  policy rather than creating a separate identity. The parent must provide a
  `COPILOT_GITHUB_TOKEN` to make that identity explicit.
