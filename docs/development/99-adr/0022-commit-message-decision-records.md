# ADR 0022: Require decision records in agent commit messages

Require every agent-created commit to preserve why its change was chosen in an ADR-lite body.

## Status

Accepted

## Context

The existing repository instruction required an English Conventional Commits
subject, but it did not require a commit body. An agent could therefore leave a
useful description of *what* changed while losing the problem, trade-offs, and
constraints that explain *why* it changed.

Full ADRs record material architecture decisions, but requiring one for every
small implementation decision would make the repository noisy and would not
help readers understand an individual commit. The commit itself is the most
durable and discoverable record for these smaller decisions.

The personal instruction file is installed for GitHub Copilot, Codex, and
Claude Code. Repository instructions additionally need an inline Copilot Code
Review mirror. This policy must be concise enough to live in both layers while
leaving examples and detailed guidance in documentation.

This repository squash merges Pull Requests with the PR body as the resulting
commit body. A rationale kept only in branch commits would be absent from the
default branch history.

## Decision

Every agent-created, non-trivial commit includes four non-empty labeled
paragraphs:

- `Context:` records the problem, trigger, or constraint.
- `Decision:` records what was adopted.
- `Considerations:` records alternatives, trade-offs, and risks weighed before
  deciding.
- `Impact:` records the resulting behavior, constraints, and follow-up work.

Routine dependency bumps, formatter-only changes, and typo fixes may use a
one- or two-sentence rationale in place of the labels. A commit subject alone
is never sufficient.

The shared personal instructions establish this rule for all installed agents.
The repository instructions add the English Conventional Commits convention,
an ADR reference rule, and the requirement to carry the same rationale into
Pull Request descriptions. They remain an exact mirror for Copilot Code
Review.

When an ADR governs a change, the commit cites `ADR NNNN` rather than
duplicating the ADR. The existing PR skills do not duplicate this policy; they
inherit it from the applicable instructions.

## Alternatives Considered

### Use `Alternatives:` as the third label

This label follows ADR terminology, but many changes have no distinct rejected
option. `Considerations:` also captures risks and trade-offs, so it is useful
for every non-trivial commit.

### Use `Consequences:` as the final label

`Consequences:` accurately describes post-decision effects, but it is too
similar to `Considerations:` when scanning `git log`. `Impact:` preserves the
meaning while making the labels easier to distinguish.

### Use a free-form explanation

Free-form prose is less consistent and harder to search. Fixed labels make
the important reasoning easy to find without requiring full Markdown ADR
headings in every commit.

### Enforce the format with a commit hook or CI

The repository has no hook-management mechanism, and mechanical validation
would either reject legitimate short-form commits or require brittle natural
language checks. The rule is enforced through agent instructions and review
instead.

### Limit the rule to Pull Request skills

Agents create commits outside the shared PR skills. The rule belongs in shared
personal and repository instructions so it applies to every agent-created
commit.

## Consequences

- Commit history preserves the reasoning needed to understand small decisions
  after an agent session ends.
- Non-trivial agent commits take more time to prepare and add body text to
  history.
- Pull Request authors must repeat the decision record in the PR description
  when squash merging.
- The policy remains guidance rather than a mechanical gate, so reviewers
  must identify incomplete decision records.
