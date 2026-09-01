# ADR 0021: Use the invoking checkout for Pull Request skills

Record the original decision to run shared Pull Request skills in the ordinary
clone that invoked them rather than provisioning a `gh-qwt` worktree.

## Status

Accepted

Supersedes [ADR 0010](./0010-pr-skills-gh-qwt.md).

> [!IMPORTANT]
> [ADR 0023](./0023-pr-skills-gh-qwt-checkouts.md) amends this decision. It
> permits PR skills in gh-qwt primary checkouts and linked worktrees. The
> remainder of this record preserves the original decision and rationale.
>
> [ADR 0033](./0033-pr-merge-batch-processing.md) amends the `pr-merge`
> single-invocation constraint for its explicit sequential batch mode.
>
> [ADR 0035](./0035-pr-skills-dedicated-worktrees.md) amends this decision
> again: `pr-fix` and `pr-merge` use deterministic per-PR worktrees checked out
> from the remote, while `pr-create` continues to use the invoking checkout.

## Context

[ADR 0010](./0010-pr-skills-gh-qwt.md) required every `pr-create`, `pr-fix`,
and `pr-merge` invocation to provision or reuse a `gh-qwt` worktree. The
policy isolated concurrent branch work, but it also made an ordinary PR
workflow create a second checkout, migrate uncommitted changes, and validate
qwt-specific path and repository metadata.

The shared PR skills should instead work in an ordinary clone where the user
started them. This keeps the visible checkout, branch, and uncommitted changes
as the single source of truth. The change removes isolation provided by
per-branch worktrees, so the skills must replace it with explicit checkout
preconditions and revalidation before mutation.

## Decision

The `pr-create`, `pr-fix`, and `pr-merge` skills operate only in the invoking
ordinary clone. They reject linked worktrees and qwt-managed checkouts.

- `pr-create` creates a feature branch in the current checkout when invoked
  from a default branch whose `HEAD` exactly matches its remote. It preserves
  intended staged, unstaged, and non-ignored untracked changes during that
  branch creation. A default branch that is ahead, behind, or diverged stops
  rather than being reset, rebased, pulled, or used as an uncertain base.
- When `pr-create` starts on a non-default branch, it uses that branch only
  after confirming that it does not already correspond to an open, closed, or
  merged PR. This prevents a checkout left on a squash-merged branch from
  silently becoming the basis of unrelated work.
- `pr-fix` and `pr-merge` require a clean ordinary clone of the PR head
  repository on the exact head branch. They accept a PR URL or a PR number
  paired with its host-qualified base repository, so a fork clone never has to
  infer the base from its `origin`. They do not create a checkout or switch
  branches. An unsuitable clone stops with the canonical repository URL and
  branch to prepare.
- The skills retain canonical GitHub identity checks, remote-head checks,
  scoped staging, review, CI, and merge safeguards. They re-check the branch,
  working state, and relevant remote SHA before commits, pushes, and merges,
  especially after polling waits.
- `pr-merge` accepts one PR per invocation. It does not delete the checked-out
  local branch or switch back to the default branch after a merge. It retains
  lease-protected remote head deletion only when the remote ref still equals
  the verified PR head SHA.
- The skills do not invoke `gh qwt`, `git worktree`, or another checkout.
  `gh-qwt` remains available for explicit interactive use.

Concurrent PR work now requires separate ordinary clones, one per active
branch or task.

## Alternatives Considered

### Keep the gh-qwt-only policy

Per-branch worktrees isolate concurrent changes and automate cleanup, but they
also force a separate checkout for every PR operation. It is not adopted
because the workflow should use the checkout in which the user invoked it.

### Switch branches automatically for every PR workflow

An agent could use `git switch` to find or prepare the head branch in a shared
checkout. It is not adopted because it can surprise a user, disrupt concurrent
work, and interact poorly with uncommitted changes. `pr-fix` and `pr-merge`
instead require the user to prepare the correct branch explicitly.

### Fall back to raw Git worktrees

Using `git worktree` would preserve isolation for ordinary clones, but it would
still create a second checkout and retain the behavior this decision removes.
It is not adopted.

### Keep multi-PR merge batches

One checkout cannot safely remain on multiple PR head branches without
automatic branch switching or worktrees. It is not adopted; callers run one
PR per invocation or use separate clones.

## Consequences

- PR creation and maintenance no longer depend on a qwt root, qwt metadata, or
  worktree path registration.
- Users must prepare the appropriate clean head checkout before fixing or
  merging a PR, particularly for fork PRs.
- Users and agents that need parallel PR work must use separate clones.
- After a merge, the local branch remains checked out. A later `pr-create`
  invocation detects its existing PR and stops instead of reusing it.
- `gh-qwt` retains its standalone repository and worktree management role; the
  shell shortcuts and existing interactive workflows remain unchanged.
