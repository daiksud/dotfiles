# 0035: Use dedicated remote-checked-out worktrees for PR maintenance

Use a verified dedicated worktree per Pull Request for fixing and merging
work, preferring an existing PR-head worktree and otherwise checking out the
deterministic candidate from the PR's remote head before any edits.

## Status

Accepted

Amends [ADR 0021](./0021-pr-skills-invoking-checkout.md) for `pr-fix` and
`pr-merge`, and amends the batch checkout behavior described in
[ADR 0033](./0033-pr-merge-batch-processing.md). `pr-create` remains governed
by ADR 0021's invoking-checkout workflow.

## Context

The invoking-checkout policy kept PR maintenance simple, but it required the
user to prepare the exact PR head branch in advance. It also made concurrent
PR work unsafe because the fixing and merging workflow had to share the
invoking checkout. The GitHub CLI now supports checking out a PR directly into
a worktree, including the remote fetch and PR-number lookup.

The maintenance and merge skills need an isolated workspace while preserving
the source checkout, its current branch, and any unrelated uncommitted work.
They also need to avoid applying fixes to a stale or unpushable PR head.

## Decision

- Keep `pr-create` in the invoking checkout. Only `pr-fix` and `pr-merge`
  provision PR worktrees.
- Derive one deterministic candidate for each PR at
  `<repository-parent>/.pr-worktrees/<base-host>/<base-owner>/<base-repo>/pr-<PR_NUMBER>`.
  Reuse a clean, registered worktree already checked out to the PR's
  `<head-branch>` when one exists outside the invoking checkout; otherwise
  reuse the candidate on retries and later invocations.
- Resolve the PR and its canonical base and head repositories before creating
  the candidate. When no existing branch worktree is selected, run
  `gh pr checkout <PR_NUMBER> -R <base-repository> --worktree
  <target-worktree>` to fetch the remote PR head and create or refresh the
  candidate. Never pass `--force` or fall back to the invoking checkout when
  worktree preparation fails.
- Require the target worktree to be registered to the invoking repository,
  clean before edits, and at the current PR `headRefOid`. Resolve its
  configured push destination, or use the canonical head repository URL when
  no destination is configured, and use an explicit `HEAD:<head-branch>`
  refspec for pushes so a disambiguated local branch is safe.
- Run all PR Git changes, validation, commits, and pushes in the target
  worktree. Keep the invoking checkout on its original branch and preserve its
  working state.
- Let batch `pr-merge` process PRs sequentially in independent worktrees
  without switching or restoring the invoking checkout. Retain clean PR
  worktrees after completion so a later maintenance invocation can reuse them.
- Delete a remote head branch only after the merged PR head SHA is revalidated
  and the deletion is protected by `--force-with-lease`.

## Alternatives Considered

### Continue using the invoking checkout

This avoids provisioning overhead, but it requires manual branch preparation
and prevents safe concurrent PR work. It is retained only for `pr-create`,
which intentionally operates on the user's current changes.

### Use `gh-qw` worktree paths

`gh-qw` remains the repository and interactive worktree manager, but its
standard path is keyed by repository and branch. The PR skills need a stable
target keyed by the requested PR number and a direct PR checkout that handles
the remote PR ref, so they use the native GitHub CLI command instead.

### Construct worktrees with raw `git worktree`

Raw Git can create the directory, but the skill would have to duplicate
GitHub CLI's PR resolution, fork handling, and remote ref setup. The native
command provides those operations as one verified preparation step.

## Consequences

- Fixing and merging a PR no longer changes the invoking checkout or its
  uncommitted files.
- A clean deterministic worktree remains available for follow-up fixes and
  review retries.
- An existing clean worktree for a PR head branch can be reused without
  attempting to check out that branch a second time.
- The source checkout needs a resolvable base repository and a GitHub CLI with
  `gh pr checkout --worktree`; unsupported clients stop safely.
- Each PR consumes a registered worktree until the user removes it. The skills
  do not force-remove a colliding or dirty target.
- Fork PRs can use the same flow only when the target worktree has verified
  push access to the canonical fork head repository.
