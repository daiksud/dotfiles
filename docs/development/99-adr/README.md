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
| [0011](./0011-ci-and-shell-testing.md) | Add a CI workflow with bats-core tests and mise-provisioned lint tools | Accepted |
| [0012](./0012-github-actions-sha-pinning.md) | Require immutable SHA pins for GitHub Actions | Accepted |
| [0014](./0014-rumdl-markdown-tooling.md) | Use rumdl for Markdown formatting and linting | Accepted |
| [0015](./0015-herdr-terminal-multiplexer.md) | Adopt herdr as the terminal multiplexer | Accepted |
| [0016](./0016-ghostty-herdr-autostart.md) | Auto-start herdr from Ghostty | Accepted |
| [0017](./0017-herdr-prefix-ctrl-t.md) | Change herdr's prefix key to `ctrl+t` | Accepted |
| [0026](./0026-vite-plus-toolchain.md) | Manage Node.js and Bun with Vite+ | Accepted |
| [0029](./0029-owner-default-gh-account-mapping.md) | Use owner defaults with repository overrides for GitHub accounts | Accepted |
| [0034](./0034-herdr-service-restart-on-upgrade.md) | Restart Herdr after an incompatible Homebrew upgrade | Accepted |

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
