# Commit Messages

This page defines how agent-created commits record the reasoning behind a change.

## Subject

Follow the repository's subject-line convention. In this repository, subjects
are English Conventional Commits:

```text
<type>(<scope>): <description>
```

The subject names the change. The body records why the change was chosen, so a
subject-only commit is never acceptable.

## Required Decision Record

Every non-trivial agent-created commit has all four of these non-empty
paragraphs:

| Label | Record | Answer |
| --- | --- | --- |
| `Context:` | Problem, trigger, or constraint | Why was a change needed? |
| `Decision:` | The chosen implementation or policy | What was adopted? |
| `Considerations:` | Options, trade-offs, and risks weighed before deciding | Why this decision rather than another approach? |
| `Impact:` | Resulting behavior, constraints, and follow-up work | What changes for readers, users, or future work? |

`Considerations:` captures reasoning before the decision. `Impact:` captures
the effects after it. Both are required even when the conclusion is that no
viable alternative, user-visible behavior change, or follow-up work exists.

```text
feat(cache): add a configurable retry delay

Context: Temporary network failures caused immediate retries that overloaded
the upstream service.
Decision: Add a configurable delay before retrying a failed request.
Considerations: A fixed delay was rejected because service limits differ
between deployments; exponential backoff was unnecessary for the current
single-retry policy.
Impact: Administrators can tune the delay for their service limits, and retry
latency becomes observable in request timing.
```

Describe the decision, not a line-by-line account of the diff.

## Short Form for Trivial Changes

Only routine dependency bumps, formatter-only changes, and typo fixes may
replace the four labels with a one- or two-sentence body. The body still states
why the change was made.

```text
chore(deps): bump example-lib to 1.4.2

This routine patch release adopts an upstream bug fix and introduces no
project-level design decision.
```

When it is unclear whether a change is trivial, use the full decision record.

## Relationship to ADRs

An ADR remains the source of truth for a material, long-lived architectural
decision. Create or update an ADR when a change selects a lasting architecture,
tool, workflow, or policy with meaningful alternatives. In the commit body,
cite the applicable record as `ADR NNNN` instead of restating its full
rationale.

The decision record in a commit captures the rationale for the specific change
that implements, refines, or follows an ADR. It does not replace the ADR.

## Pull Request Descriptions

This repository's squash-merge configuration uses the Pull Request body as the
resulting commit body. For every non-trivial Pull Request, include the same
context, decision, considerations, and impact in its description. Otherwise,
the decision record from the branch commit does not reach the default branch.
