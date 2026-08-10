# ADR 0028: Use the host's native subagent deployment

Do not impose Herdr pane or tab orchestration on subagent deployment.

## Status

Accepted

## Context

[ADR 0024](./0024-herdr-subagent-fanout.md) made Herdr panes and tabs the
default location for subagents launched from a Herdr-managed pane. The policy
required a shared Herdr fan-out skill, prescribed layouts based on agent count,
and added lifecycle cleanup rules that were unrelated to the work being
delegated.

[ADR 0025](./0025-copilot-token-parent-context.md) extended that skill with a
temporary Zsh bootstrap for forwarding `COPILOT_GITHUB_TOKEN`. This coupled
subagent authentication to Herdr and added credential-handling behavior to a
terminal-layout workflow.

The host coding agents already provide native subagent facilities. The
repository should not override those facilities based on the terminal
multiplexer in which the parent happens to run.

## Decision

- Remove the former Herdr fan-out skill and the personal-instruction rule that
  routed Herdr subagent deployments to it.
- Use each host's native subagent facility for all subagent deployments. Herdr
  remains available as the terminal multiplexer for interactive work, but it
  does not control subagent tabs or panes.
- Remove the Herdr-specific Copilot token bootstrap. `COPILOT_GITHUB_TOKEN`
  remains parent-owned: `gh-account.zsh` never reads, sets, or clears it, and
  users may configure it through their approved credential-management method.
- When `install.sh` updates configured skill roots, remove only stale symbolic
  links that resolve under the canonical skills directory and whose resolved
  directory no longer contains `SKILL.md`. Preserve real directories,
  external links, and canonical sources when a target root aliases the
  canonical directory.

## Alternatives Considered

### Keep the skill without layout rules

This would retain Herdr-specific lifecycle and credential behavior without
providing a stable layout contract. It was rejected because the host's native
facility already owns subagent lifecycle.

### Keep the skill but use new tabs only

This would remove caller-tab pane splits but would still impose terminal
topology and cleanup on every host. It was rejected for the same coupling
reason.

### Move the token bootstrap into personal instructions

This would preserve parent-token forwarding but make always-loaded
instructions responsible for product- and shell-specific credential
transport. It was rejected because host-native authentication should own that
context and the repository should not duplicate it.

## Consequences

- Subagent placement, focus, lifecycle, and result collection follow the
  invoking host rather than Herdr.
- Existing installations may contain stale links for the removed skill;
  re-running `install.sh` removes those links without deleting unrelated
  skills or canonical source directories.
- `gh-account.zsh` continues to manage GitHub CLI and Git identity only.
  Parent-provided `COPILOT_GITHUB_TOKEN` is not modified by this repository.
- The Herdr multiplexer remains supported for terminal sessions, but no
  repository instruction promises that subagents appear in Herdr panes or
  tabs.
