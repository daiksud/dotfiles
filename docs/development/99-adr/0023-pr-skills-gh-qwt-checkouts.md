# ADR 0023: Allow Pull Request skills in gh-qwt checkouts

Allow shared Pull Request skills to use an invoking gh-qwt primary checkout or
linked worktree without provisioning another checkout.

## Status

Superseded by [ADR 0027](./0027-gh-qw.md)

Amended [ADR 0021](./0021-pr-skills-invoking-checkout.md).

## Context

ADR 0021 moved the shared Pull Request skills away from automatically
provisioned worktrees and into the checkout where the user invoked them. Its
implementation still required a real `.git` directory and rejected any
checkout where `qwt.managed` was `true`.

That guard blocks every checkout in a gh-qwt-managed repository. The metadata
is repository-local and linked worktrees share the primary checkout's Git
common directory, so `qwt.managed=true` is visible from the primary checkout
and every linked worktree. The real-`.git` condition independently rejects the
linked worktrees whose `.git` entries are pointer files.

The actual safety requirement differs by operation. `pr-fix` and `pr-merge`
never create or switch a branch: they already require the current branch to
equal the verified PR head, the checkout to be clean, and `origin` to match
the head repository. `pr-create` creates a branch only after confirming an
exactly synchronized default branch or selecting an eligible existing
non-default branch.

gh-qwt itself requires its primary checkout to remain on the metadata-pinned
default branch before its management commands will operate. Git permits that
checkout to move to a feature branch, but gh-qwt validates the pin and rejects
the repository until the branch is restored. This is an operational consequence
to report, not a reason to reject a user-selected checkout.

## Decision

The `pr-create`, `pr-fix`, and `pr-merge` skills accept any invoking Git
checkout: an ordinary clone, a gh-qwt primary checkout, or a linked worktree.
They no longer require a real `.git` directory or reject
`qwt.managed=true`.

- The skills still do not create or use `gh qwt`, `git worktree`, or another
  checkout. They use only the checkout in which the request started.
- `pr-create` retains its exact default-branch synchronization requirement.
  Before creating a target branch, it reads `git worktree list --porcelain`
  and stops with the registered path if another worktree has that branch
  checked out.
- When `pr-create` moves a gh-qwt primary checkout from `qwt.defaultbranch` to
  a feature branch, it proceeds without a confirmation prompt. It reports that
  gh-qwt management commands will reject the repository until the user safely
  restores the pinned branch; it never switches the branch back automatically.
- `pr-fix` and `pr-merge` continue to require a clean checkout of the verified
  PR head repository and branch. Their existing identity, branch, working
  state, remote-head, and post-wait revalidation rules remain unchanged.
- Concurrent PR work uses separate checkouts. A linked worktree is suitable
  when a user needs another branch of the same repository in parallel.

The upstream `gh-qwt-worktree-first` skill required the opposite policy:
never use the primary checkout for task work. Its independently installed copy
under `~/.codex/skills/` is removed so it cannot override this policy.

## Alternatives Considered

### Ask before moving the gh-qwt primary checkout

An explicit confirmation would make the primary-branch consequence visible
before the branch changes. It was not adopted because the PR skills should
treat a user-selected primary checkout like an ordinary clone and already
report the consequence. A prompt would make the workflow inconsistent without
adding Git safety.

### Require a linked worktree for every gh-qwt task

This follows the upstream `gh-qwt-worktree-first` skill and keeps the primary
available to gh-qwt management commands. It was not adopted because users
intentionally work in ghq primary clones and create linked worktrees only for
parallel tasks. The safety rules of the PR skills do not require a second
checkout.

### Keep rejecting gh-qwt-managed checkouts

The existing guards protect the primary's gh-qwt registration, but they also
make every gh-qwt checkout unusable by the PR skills. This leaves users to
create an unrelated clone solely for a PR workflow and rejects an already
isolated linked worktree without a Git safety justification.

## Consequences

- PR skills work in the gh-qwt checkouts that users already selected.
- A primary checkout moved off `qwt.defaultbranch` remains a usable Git
  checkout, but gh-qwt management commands reject the repository until the
  user restores the pinned branch.
- The skills report that consequence and never switch, clean, stash, or reset
  the primary automatically.
- `git worktree list --porcelain` is read-only and may be used to report branch
  collisions without violating ADR 0021's prohibition on provisioning another
  checkout.
- The standalone `gh-qwt-worktree-first` skill is no longer installed in the
  local Codex skill root. It is outside this repository's managed skill
  targets, so this environment change is not represented by a tracked file.
