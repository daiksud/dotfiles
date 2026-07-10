# ADR 0008: Replace gh-q and gh-wt with gh-qwt

Adopt the `gh-qwt` GitHub CLI extension, which unifies repository cloning and per-branch worktree management, replacing the separate `gh-q` and `gh-wt` extensions.

## Status

Accepted

## Context

This repository previously adopted two separate GitHub CLI extensions for related but distinct jobs:

- [ADR 0004](./0004-gh-q.md) adopted `gh-q` (`HikaruEgashira/gh-q`) to clone and list repositories under `~/ghq/github.com/<owner>/<repo>`, replacing the standalone `ghq` binary.
- [ADR 0007](./0007-gh-wt.md) adopted `gh-wt` (`HikaruEgashira/gh-wt`) to create and manage copy-on-write (CoW) backed git worktrees, for running multiple worktrees of the same repository side by side.

`gh-qwt` (`daiksud/gh-qwt`) is a newer GitHub CLI extension that covers both jobs with a single tool: it clones a repository once as a bare git database and gives every branch its own worktree directory under `<qwt_root>/<owner>/<repo>/<branch>`. Keeping `gh-q` and `gh-wt` alongside `gh-qwt` would mean maintaining three overlapping ways to reach a repository or a branch checkout, with no benefit over standardizing on the one tool that already covers both.

## Decision

Replace both `gh-q` and `gh-wt` with `gh-qwt`.

- Install it with `gh extension install daiksud/gh-qwt` in `scripts/100-gh-extensions.sh`, removing the `HikaruEgashira/gh-q` and `HikaruEgashira/gh-wt` entries
- Consolidate the zsh shortcuts: rewrite `go-to-ghq-repository.zsh` (`ggr`) as `go-to-qwt-repository.zsh`, absorbing the former `go-to-worktree.zsh` (`gwt`)'s role, since `gh qwt list` already returns a single flat `owner/repo/branch` list covering both repositories and worktrees; rewrite `edit-ghq-repository.zsh` as `edit-qwt-repository.zsh` to fzf-select from `gh qwt list --full-path` directly instead of delegating to `gh-q`'s built-in fzf dispatch
- Remove the `go-to-worktree.zsh` file and the `gwt` alias, now that `ggr` covers the same ground
- Remove the `dotfiles/skills/gh-wt/` Copilot CLI skill (vendored from upstream via `gh skill install HikaruEgashira/gh-wt gh-wt`) without a replacement, since `daiksud/gh-qwt` does not currently ship a skill to vendor
- Document the new tool in [reference/gh-qwt.md](../../reference/gh-qwt.md), replacing `reference/gh-wt.md`

## Alternatives Considered

### Keep gh-q and gh-wt

Works, and loses nothing functionally by itself, but leaves three tools (`gh-q`, `gh-wt`, and any future unified tool) doing overlapping jobs, and does not benefit from `gh-qwt`'s single shared bare repository per project. Not adopted, since there is no reason to keep two tools for what `gh-qwt` already does together.

### Wait for an upstream Copilot skill before switching

`gh-wt`'s skill was vendored directly from its upstream repository. Waiting for `daiksud/gh-qwt` to ship an equivalent skill before switching would keep the agent-driven worktree workflow available throughout the migration. Not adopted — the user-facing command-line workflows (`ggr`, `egr`, and direct `gh qwt` usage) do not depend on the skill, and there is no committed timeline for an upstream skill.

### Hand-author a new gh-qwt skill now

A skill could be written in this repository's own hand-authored format (like `pr-create`) to restore natural-language worktree/repository requests immediately. Not adopted for this change — deferred until there is a clearer, tested interaction pattern for `gh-qwt`'s path-printing-only design (see Consequences below), to avoid shipping a skill that has to be substantially rewritten soon after.

## Consequences

- **No CoW-backed worktrees.** `gh-qwt` creates worktrees with a plain `git worktree add` against a shared bare repository; only the git object database is shared, not the working-tree files. The disk savings that motivated ADR 0007 (roughly 8x less disk at 10 concurrent worktrees, 13x at 20, versus plain `git worktree add`) no longer apply.
- **No built-in command dispatch.** Unlike `gh q -- <cmd>` / `gh wt -- <cmd>` / `gh wt <cmd>`, `gh-qwt` has no "fzf-select, then run a command" mode. Only `gh qwt path` / `gh qwt list --full-path` print paths; the `ggr`/`egr` zsh functions (or manual `cd "$(gh qwt path <spec>)" && <command>`) are now required to act on a selection.
- **New root directory.** `gh-qwt` stores repositories under `~/qwt` by default (configurable via `QWT_ROOT` or `git config qwt.root`), independent of `gh-q`'s old `~/ghq/github.com` layout and of ghq's `GHQ_ROOT`. Existing clones under `~/ghq` are left in place; this change does not migrate or delete them, and re-cloning repositories with `gh qwt get` as needed is a manual, on-demand step.
- **No Copilot CLI skill for gh-qwt.** Natural-language requests to create, list, or remove worktrees no longer automatically trigger a skill until one is authored or vendored later (see Alternatives Considered).
- [ADR 0004](./0004-gh-q.md) and [ADR 0007](./0007-gh-wt.md) are marked Superseded by this ADR.
