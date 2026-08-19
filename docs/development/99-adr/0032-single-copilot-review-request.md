# 0032: Let pr-merge own the single Copilot review request

Give `pr-merge` exclusive ownership of the Copilot Code Review request when it
invokes `pr-fix`, instead of letting both skills request one in the same
iteration.

## Status

Accepted

## Context

`pr-fix` requests Copilot Code Review itself once the base branch's rules
enable it (see [ADR 0018](./0018-pr-review-requirements.md)). `pr-merge`'s
retry loop also requests a Copilot Code Review and waits for it in Step 1, and
that same step invokes `pr-fix` in `all` mode for the PR. Both skills could
therefore each request a review for the same PR within one iteration, risking
duplicate or conflicting Copilot review requests.

## Decision

- Add a `--skip-copilot-review` flag that `pr-fix` accepts.
- `pr-merge` passes this flag every time it invokes `pr-fix`.
- When the flag is set, `pr-fix`'s feedback mode still retrieves, evaluates,
  and replies to review comments and resolves their threads, but it skips its
  own post-feedback Copilot Code Review request and reports that the caller
  owns it.
- `pr-merge` remains the sole caller that requests and waits for the Copilot
  Code Review each retry iteration.

## Alternatives Considered

### Drop pr-merge's own request and always let pr-fix request the review

`pr-fix` is also used standalone outside of `pr-merge`, so it must keep
requesting a review by default. `pr-merge`'s retry loop also needs a precise
request timestamp to distinguish a fresh review from a stale one across
iterations; delegating the request to `pr-fix` would require passing that
timestamp back out, which is more coupling than a flag.

### Let pr-fix detect a pr-merge caller implicitly

Inferring the caller from environment or process context instead of an
explicit flag would create a hidden coupling between the two skills that does
not survive different host agents or invocation methods, and it conflicts with
the portability requirements in
[`docs/reference/skills.md`](../../reference/skills.md).

## Consequences

- `pr-merge` and `pr-fix` no longer race to request Copilot Code Review on the
  same PR.
- `pr-fix`'s `Inputs` documents the flag, and its feedback mode stops before
  querying rules or requesting a review when the flag is present.
- `docs/reference/skills.md` documents `pr-merge` as the owner of the single
  request when it invokes `pr-fix` internally.
