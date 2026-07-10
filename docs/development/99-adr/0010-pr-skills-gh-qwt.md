# ADR 0010: Use gh-qwt worktrees for Pull Request skills

Run all Pull Request skill branch workflows in `gh-qwt` worktrees instead of switching branches in a shared checkout.

## Status

Accepted

## Context

The `pr-create` skill previously instructed agents to create and check out a
feature branch from `main`, while `pr-fix` instructed them to check out the
Pull Request branch. Those instructions conflict with the repository's
[`gh-qwt`](../../reference/gh-qwt.md) model: each branch has a separate
worktree below one shared bare repository.

Using a single checkout for PR work also makes a dirty default branch,
parallel PR fixes, and branch cleanup during merge unnecessarily fragile. In
particular, `gh pr merge --delete-branch` cannot safely delete a local branch
while its worktree remains checked out. When `-R` is required to target a base
repository, GitHub CLI intentionally skips local branch deletion; for
cross-repository PRs it also skips remote head deletion.

## Decision

The `pr-create`, `pr-fix`, and `pr-merge` skills use `gh-qwt` as their only
branch-workspace mechanism.

- Resolve or create a branch worktree with `gh qwt get` and `gh qwt add`, then
  obtain its absolute path with `gh qwt path`.
- Run repository commands against the resolved path, using `git -C <path>`
  where a Git command needs an explicit working directory.
- Do not run `git switch`, `git checkout`, or a normal-clone branch-switching
  fallback in these skills. Do not fall back to `git worktree`.
- When `pr-create` starts with uncommitted changes on the default branch,
  migrate them only through a reversible, verified transfer to a newly created
  qwt worktree. Local commits on the default branch are not reset, rebased, or
  otherwise rewritten automatically.
- Have `pr-fix` resolve the PR head repository and branch. A fork PR uses a
  worktree for its head repository; a missing fork or insufficient push access
  is reported rather than worked around by creating a branch in the base
  repository.
- Have `pr-merge` merge with the verified PR head SHA and without
  `--delete-branch`. After GitHub confirms the merge, remove the clean qwt
  worktree and local branch with `gh qwt remove --delete-branch` from outside
  every qwt repository, then delete the head remote branch from its own qwt
  repository with a lease for the verified head SHA. This works consistently
  for same-repository and fork PRs without a branch checkout.

This is a skill-level policy. The shell remains free to use normal Git branch
commands outside the PR skills.

## Alternatives Considered

### Keep branch checkout instructions

This keeps the existing skill text shorter, but places concurrent work and
dirty default-branch changes in one checkout. It is not adopted because it
does not use the worktree model established by ADR 0008.

### Fall back to `git worktree` for ordinary clones

This would support legacy clones without provisioning a qwt repository, but it
would create two competing workspace layouts and inconsistent cleanup
semantics. It is not adopted; `gh qwt get` provisions the canonical layout
when needed.

### Block `git switch` and `git checkout` in Zsh

A shell wrapper could make the policy global, but it would alter ordinary Git
usage and could still be bypassed by another Git executable path. It is not
adopted because the requirement applies to agent-driven PR workflows, not all
interactive Git work.

### Require users to prepare every worktree manually

This avoids migration logic, but makes a PR skill fail precisely when it is
most useful: before its first qwt worktree exists. It is not adopted because
the skills can provision a worktree deterministically with `gh-qwt`.

## Consequences

- PR work can remain isolated per branch and parallel PR operations do not
  require a branch switch.
- A first use from a repository without a qwt checkout may clone the
  repository into the qwt root.
- A qwt path conflict, unavailable `gh qwt`, missing or deleted fork, dirty
  worktree at merge time, or unsafe default-branch migration stops the skill
  with an actionable error. It must not silently fall back to a checkout.
- Feature worktrees remain after `pr-fix` for subsequent iterations. A
  successful `pr-merge` removes the corresponding clean worktree and local
  branch, then attempts lease-protected head-remote cleanup. A remote cleanup
  failure is reported without misrepresenting an already merged PR as
  unmerged.
