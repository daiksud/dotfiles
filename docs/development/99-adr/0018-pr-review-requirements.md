# 0018: Evaluate repository review requirements before PR automation

Query GitHub's live state before requesting optional reviews or approvals in
the Pull Request skills.

## Status

Superseded by [ADR 0036](./0036-pr-review-availability.md)

## Context

The `pr-fix` and `pr-merge` skills previously requested Copilot Code Review
for every Pull Request. `pr-merge` also applied the `self approval` label and
waited for an approval even when the repository did not require one.

These assumptions fail across repositories. Copilot Code Review can be absent
from the effective rules for a base branch, while approval requirements can
come from repository or organization rules. A checked-in settings file cannot
represent every live rule that GitHub applies.

## Decision

- Query the active rules for the PR base branch from the canonical base host.
  Treat Copilot Code Review as enabled only when the effective response
  contains a `copilot_code_review` rule.
- Stop the affected PR when the rules query fails. Do not convert an unknown
  state into either an enabled or disabled result.
- After marking a PR ready, use GitHub's computed `reviewDecision` to decide
  whether approval is unnecessary (null or empty), already satisfied, or
  still required.
- Request the `self approval` workflow only when review is required and no
  valid approval exists. Re-check `reviewDecision` across retries.
- Make both decisions per PR and report every deliberate skip.

## Alternatives Considered

### Always request reviews and approval

This preserves the previous linear workflow, but it waits for features or
automation that may not exist and can fail on a missing label.

### Read `.github/settings.yml`

The declarative file is useful for this repository, but it does not capture
organization-level rules, settings outside gh-infra, or another repository's
live state.

### Infer approval only from rule parameters

Combining every ruleset and classic branch-protection parameter would
duplicate GitHub's own evaluation. `reviewDecision` expresses the effective
result for the actual Pull Request after it is ready.

### Continue when the rules query fails

Treating an API, permission, or network failure as a disabled feature could
silently omit a required review. Treating it as enabled recreates the original
failure mode. Stopping keeps the uncertainty visible.

## Consequences

- Repositories without Copilot Code Review avoid unnecessary review requests
  and waits.
- Repositories without required approval do not need the `self approval`
  label or its automation.
- The workflow depends on the live rules API and stops when availability
  cannot be established.
- Documentation and skill output must distinguish performed, skipped, and
  failed review automation.
