# 0033: Process ordered same-repository PR merge batches

Allow `pr-merge` to process an explicit ordered PR list or all open
same-repository PRs sequentially without provisioning another checkout.

## Status

Accepted

## Context

`pr-merge` previously accepted exactly one Pull Request and required the
invoking checkout to remain on that PR's head branch. That protects the
checkout and keeps the skill compatible with fork PRs, but it forces users to
start a separate invocation for every PR and makes a repository-wide merge
operation cumbersome.

The requested batch operation must still use the current checkout, preserve
the existing `pr-fix` and review safeguards, and avoid worktree provisioning.
Different PRs normally use different branches, so a batch needs an explicit
and bounded exception to the no-branch-switch rule. Fork heads cannot be
processed through a checkout whose `origin` is the target repository without
changing repository identity, so they need a clear batch boundary.

## Decision

- Accept one PR URL as the unchanged single-PR form.
- Accept one or more PR numbers followed by an optional host-qualified base
  repository. When the base is omitted, resolve the current checkout's
  canonical `origin`. Accept `all` with the same optional base.
- Preserve the supplied order for explicit numbers. For `all`, snapshot all
  open PRs, including Drafts, paginate to completion, and sort by ascending
  PR number.
- Keep single-PR mode on the exact verified head checkout without automatic
  branch switching. In batch mode, require a clean checkout whose `origin`
  is the target base repository and switch only between verified,
  same-repository head branches.
- Never create or use a `gh-qw`, Git, or other worktree for a batch. Prepare a
  missing local branch from its exact remote ref, fast-forward a strictly
  behind branch, and stop that PR on divergence, branch collision, remote
  identity change, or missing head ref. Never reset, discard, stash, or
  force-push to make a switch possible.
- Run the existing per-PR retry loop independently, including its Copilot
  review request ownership and persistent approval state. A clean per-PR
  failure is recorded and does not prevent a later PR from being attempted.
  Dirty or conflicted state stops the batch without destructive recovery.
- After the queue finishes, restore the branch that was checked out at batch
  start. Retain local branches and keep the existing lease-protected remote
  head cleanup after a successful merge.
- Record merged, failed, and skipped PRs separately. Skip fork heads in batch
  mode rather than rewriting `origin` or creating a substitute checkout.

## Alternatives Considered

### Keep one PR per invocation

This preserves the smallest checkout surface and the original safety rule, but
requires repeated user setup and cannot provide the requested ordered or
repository-wide operation. It is retained as the single-PR mode.

### Provision a `gh-qw` worktree per PR

Separate worktrees would isolate branches and support fork heads, but they
would reintroduce automatic checkout provisioning that the current PR skill
policy intentionally removed. It would also require cleanup and additional
repository identity handling for every item in a batch.

### Switch branches even when the checkout is unsafe

Forcing a switch, discarding changes, or stashing unresolved conflict state
could allow more PRs to run, but it would hide recoverable work and make a
partial batch destructive. The batch stops instead.

### Include fork PRs by rewriting `origin`

Changing the invoking checkout's remote would violate canonical identity
verification and could push fixes to the wrong repository. Fork PRs remain
available through the single-PR workflow from their own head checkout.

## Consequences

- Users can merge a deterministic ordered list or a snapshot of all open
  same-repository PRs from one clean checkout.
- Batch mode may leave several local head branches after returning to the
  starting branch; it never silently deletes them.
- A failed PR can prevent later PRs when it leaves a dirty or conflicted
  checkout, so `continue` is best effort rather than a promise to bypass
  safety checks.
- Draft PRs are included in `all` and go through the existing ready-for-review
  step. Fork PRs are visible in the result as skipped rather than silently
  omitted.
- ADR 0021's one-PR and no-branch-switch wording remains the default for
  single-PR operation and is amended only for this explicit batch mode.
