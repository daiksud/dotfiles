# ADR 0025: Keep Copilot tokens in the parent context

Use a parent-supplied `COPILOT_GITHUB_TOKEN` to pin every Herdr Copilot child
to the same user without coupling Copilot authentication to GitHub CLI account
selection.

## Status

Superseded by [ADR 0028](./0028-native-subagent-deployment.md)

## Context

`gh-account.zsh` selects a GitHub CLI account per repository and exports its
token as `GH_TOKEN`. It also used to clear and regenerate
`COPILOT_GITHUB_TOKEN` whenever the shell synchronized its repository identity.

Herdr starts each subagent in a fresh shell. A Copilot child must use exactly
the same user as its parent, but a repository mapping is not the authoritative
source for the parent's Copilot identity. Rewriting a caller-supplied Copilot
token during shell startup can change that identity or discard the explicit
token needed to pin it. Passing credentials through prompts, files, or logs is
not acceptable.

## Decision

- `gh-account.zsh` manages only `GH_TOKEN`, `GH_CONFIG_DIR`, and injected Git
  identity variables. It never reads, exports, or clears
  `COPILOT_GITHUB_TOKEN`.
- A Copilot parent that deploys Herdr subagents must have a nonempty
  `COPILOT_GITHUB_TOKEN`. The `herdr-subagents` skill writes it to a mode-600
  file inside a mode-700 temporary directory, then passes only that directory
  as the child pane's `ZDOTDIR`.
- The temporary `.zshenv` loads the token, restores the normal `ZDOTDIR`, and
  explicitly sources the parent's original `.zshenv` before the rest of the
  regular Zsh startup continues. After every Copilot child confirms token
  presence, the skill removes both credential files and their directory before
  starting the agents.
- The skill never places the token in process arguments, output, or prompts,
  and never replaces it. It does not run a Copilot login, logout, user switch,
  or host change.
- If the token is unavailable, the skill does not start a Copilot child with an
  uncertain identity. It uses the native subagent fallback and reports why.

## Alternatives Considered

### Derive Copilot authentication from the repository account mapping

The mapping is authoritative for `gh` and Git operations, but a parent Copilot
session can intentionally use a different account. Re-deriving its token in
each fresh pane can silently change the child's identity, so this was rejected.

### Rely on Copilot's credential store

The credential store can often authenticate a child, but it does not make the
selected user explicit when several accounts are available. It was rejected
because the parent token is the precise, verifiable context to preserve.

### Put the token directly in Herdr's `--env` argument

This would be simpler, but the expanded `KEY=VALUE` becomes part of Herdr's
process arguments and can be visible to process inspection. It was rejected in
favor of passing only a private bootstrap path.

### Store or transmit the token through a persistent file or prompt

This would make forwarding easier to inspect, but it risks exposing a
credential in repository state, terminal scrollback, or logs. It was rejected
in favor of an ephemeral, permission-restricted bootstrap removed before agent
startup.

## Consequences

- Copilot parent and child agents use the same token, user, quota, and account
  policy when fan-out is enabled.
- GitHub CLI and Git retain independent per-repository account selection
  through `gh-account.zsh`.
- Users must configure the parent token through an approved credential
  management method before launching Copilot subagents.
- Copilot fan-out currently requires Zsh so `.zshenv` can provide the
  secret-safe startup handoff. Other shells fail closed to the native fallback.
- A missing token fails safely to the native subagent mechanism instead of
  launching a child as an unknown user.
