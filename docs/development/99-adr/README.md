# ADR

This page records decisions about technical choices in dotfiles.

## What is an ADR?

An ADR (Architecture Decision Record) is a document for recording important technical decisions, including the background, the decision itself, and its impact.

## ADR List

| ID                                      | Title                                                   | Status     |
| --------------------------------------- | ------------------------------------------------------- | ---------- |
| [0001](./0001-json-install-map.md)      | Adopt a JSON mapping table for symbolic link management | Accepted   |
| [0002](./0002-ssh-commit-signing.md)    | Adopt SSH commit signing                                | Accepted   |
| [0003](./0003-sheldon-starship.md)      | Replace Oh-My-Zsh with Sheldon + Starship               | Accepted   |
| [0004](./0004-gh-q.md)                  | Replace ghq with gh-q                                   | Superseded |
| [0005](./0005-gh-infra.md)              | Manage repository settings declaratively with gh-infra  | Accepted   |
| [0006](./0006-per-app-tmux-sessions.md) | Per-application tmux sessions on terminal launch        | Accepted   |
| [0007](./0007-gh-wt.md)                 | Manage git worktrees with gh-wt                         | Superseded |
| [0008](./0008-gh-qwt.md)                | Replace gh-q and gh-wt with gh-qwt                      | Accepted   |
| [0009](./0009-shared-worktree-gh-auth.md) | Share gh authentication across Git worktrees           | Accepted   |
| [0010](./0010-pr-skills-gh-qwt.md)        | Use gh-qwt worktrees for Pull Request skills           | Accepted   |
| [0011](./0011-ci-and-shell-testing.md)    | Add a CI workflow with bats-core tests and mise-provisioned lint tools | Accepted |

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
