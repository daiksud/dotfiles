# 0036: Skip unavailable optional PR automation

Allow Pull Request maintenance and merge workflows to continue when optional
review automation is unavailable or unnecessary.

## Status

Accepted

Supersedes [ADR 0018](./0018-pr-review-requirements.md) for the
unavailable-review and no-approval-needed cases.

## Context

The PR skills query GitHub's live branch rules before requesting Copilot Code
Review. Some repositories cannot use the rules endpoint because of plan,
permission, or feature-availability limitations even when their Pull Requests
can otherwise pass CI and merge. Treating that unavailable optional feature as
a hard failure prevents safe maintenance and merge operations.

The `self approval` workflow is also optional. GitHub's computed Pull Request
state can show that no approval is required, or that a Pull Request is
mergeable without an approval blocker. Applying a label in those cases adds
unnecessary automation and can fail when the label does not exist.

## Decision

- `pr-fix` and `pr-merge` skip Copilot Code Review when the feature or its
  rules endpoint is unavailable, including plan and permission limitations.
  They report that the review was skipped and continue the workflow.
- A successful rules query that contains no `copilot_code_review` rule also
  skips the review as disabled.
- `pr-merge` uses GitHub's computed `reviewDecision`, `mergeable`, and
  `mergeStateStatus` after the PR is ready. It skips the `self approval` label
  and approval wait when approval is not required or the PR is mergeable
  without an approval blocker.
- `pr-merge` applies the existing `self approval` label only when approval
  still blocks the PR and no valid approval exists. If the label is missing,
  it re-checks the computed state and continues only when the PR can merge
  without the label.
- `pr-create` only creates a draft PR and does not request Copilot Code Review
  or apply the `self approval` label.
- Every optional-review and approval decision is reported per PR.

## Alternatives Considered

### Stop whenever the rules endpoint is unavailable

This preserves strict certainty about the optional review configuration, but
it blocks repositories where the feature is unavailable by platform plan or
permission while the PR itself is mergeable. The user-facing merge workflow
would fail for an optional check rather than relying on GitHub's actual PR
state.

### Always apply the `self approval` label

This can trigger approval automation when it is needed, but it creates
unnecessary labels and fails in repositories that do not define the label or
do not require approval. GitHub's computed merge state is a more direct
signal.

## Consequences

- PR maintenance and merging can proceed without Copilot Code Review when
  GitHub cannot provide that optional feature.
- Required approval is still honored when GitHub reports that it blocks the
  PR, and the existing label/automation remains the only path for that case.
- A missing label is non-blocking only when GitHub confirms that the PR can
  merge without approval.
- Skill output must distinguish requested reviews, disabled reviews,
  unavailable reviews, and unnecessary self approval.
