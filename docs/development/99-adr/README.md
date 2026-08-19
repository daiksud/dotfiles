# ADR

This page records decisions about technical choices in dotfiles.

## What is an ADR?

An ADR (Architecture Decision Record) is a document for recording important technical decisions, including the background, the decision itself, and its impact.

## ADR List

| ID | Title | Status |
| --------------------------------------- | ------------------------------------------------------- | ---------- |
| [0001](./0001-json-install-map.md) | Adopt a JSON mapping table for symbolic link management | Accepted |
| [0002](./0002-ssh-commit-signing.md) | Adopt SSH commit signing | Accepted |
| [0003](./0003-sheldon-starship.md) | Replace Oh-My-Zsh with Sheldon + Starship | Accepted |
| [0004](./0004-gh-q.md) | Replace ghq with gh-q | Superseded |
| [0005](./0005-gh-infra.md) | Manage repository settings declaratively with gh-infra | Accepted |
| [0007](./0007-gh-wt.md) | Manage git worktrees with gh-wt | Superseded |
| [0008](./0008-gh-qwt.md) | Replace gh-q and gh-wt with gh-qwt | Superseded |
| [0009](./0009-shared-worktree-gh-auth.md) | Share gh authentication across Git worktrees | Superseded |
| [0010](./0010-pr-skills-gh-qwt.md) | Use gh-qwt worktrees for Pull Request skills | Superseded |
| [0011](./0011-ci-and-shell-testing.md) | Add a CI workflow with bats-core tests and mise-provisioned lint tools | Accepted |
| [0012](./0012-github-actions-sha-pinning.md) | Require immutable SHA pins for GitHub Actions | Accepted |
| [0013](./0013-cross-agent-skills-and-instructions.md) | Share Agent Skills and instructions across coding agents | Accepted |
| [0014](./0014-rumdl-markdown-tooling.md) | Use rumdl for Markdown formatting and linting | Accepted |
| [0015](./0015-herdr-terminal-multiplexer.md) | Adopt herdr as the terminal multiplexer | Accepted |
| [0016](./0016-ghostty-herdr-autostart.md) | Auto-start herdr from Ghostty | Accepted |
| [0017](./0017-herdr-prefix-ctrl-t.md) | Change herdr's prefix key to `ctrl+t` | Accepted |
| [0018](./0018-pr-review-requirements.md) | Evaluate repository review requirements before PR automation | Accepted |
| [0019](./0019-gh-qwt-ghq-layout.md) | Follow gh-qwt's ghq-compatible layout | Superseded |
| [0020](./0020-central-gh-account-mapping.md) | Select the GitHub account per repository from a central mapping | Superseded |
| [0021](./0021-pr-skills-invoking-checkout.md) | Use the invoking checkout for Pull Request skills | Accepted |
| [0022](./0022-commit-message-decision-records.md) | Require decision records in agent commit messages | Accepted |
| [0023](./0023-pr-skills-gh-qwt-checkouts.md) | Allow Pull Request skills in gh-qwt checkouts | Superseded |
| [0024](./0024-herdr-subagent-fanout.md) | Fan out subagents into Herdr panes | Superseded |
| [0025](./0025-copilot-token-parent-context.md) | Keep Copilot tokens in the parent context | Superseded |
| [0026](./0026-vite-plus-toolchain.md) | Manage Node.js and Bun with Vite+ | Accepted |
| [0027](./0027-gh-qw.md) | Replace gh-qwt with gh-qw | Accepted |
| [0028](./0028-native-subagent-deployment.md) | Use the host's native subagent deployment | Accepted |
| [0029](./0029-owner-default-gh-account-mapping.md) | Use owner defaults with repository overrides for GitHub accounts | Accepted |
| [0030](./0030-ghostty-ctrl-d-delete-key.md) | Remap `ctrl+d` to the Delete key in Ghostty | Accepted |
| [0031](./0031-ghostty-ctrl-e-end-key.md) | Remap `ctrl+e` to the End key in Ghostty | Accepted |
| [0032](./0032-single-copilot-review-request.md) | Let pr-merge own the single Copilot review request | Accepted |

## How to Write a New ADR

Create it with a sequentially numbered file name and use the following structure.

```md
# XXXX: Decision Title

A one-line summary of what the decision covers

## Status

Proposed / Accepted / Superseded / Deprecated

## Context

Write the background, problems, and constraints that made this decision necessary.

## Decision

Write what was adopted and how it will be operated.

## Alternatives Considered

### Option A

- Summary
- Why it was not adopted

## Consequences

- Benefits gained
- Constraints accepted
```

> [!TIP]
> Record the reasons for rejecting alternatives in detail. AI assistants lose context between sessions, so ADRs become the only way to recover _why_ a particular choice was made.
