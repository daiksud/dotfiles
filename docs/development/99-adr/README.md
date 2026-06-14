# ADR

This page records decisions about technical choices in dotfiles.

## What is an ADR?

An ADR (Architecture Decision Record) is a document for recording important technical decisions, including the background, the decision itself, and its impact.

## ADR List

| ID                                   | Title                                          | Status   |
| ------------------------------------ | ---------------------------------------------- | -------- |
| [0001](./0001-json-install-map.md)   | Adopt a JSON mapping table for symbolic link management | Accepted |
| [0002](./0002-ssh-commit-signing.md) | Adopt SSH commit signing                       | Accepted |
| [0003](./0003-sheldon-starship.md)   | Replace Oh-My-Zsh with Sheldon + Starship      | Accepted |
| [0004](./0004-gh-q.md)               | Replace ghq with gh-q                          | Accepted |
| [0005](./0005-gh-infra.md)           | Manage repository settings declaratively with gh-infra | Accepted |

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
> Record the reasons for rejecting alternatives in detail. AI assistants lose context between sessions, so ADRs become the only way to recover *why* a particular choice was made.
