# ADR 0012: Require immutable SHA pins for GitHub Actions

Require every GitHub Actions workflow action to reference an immutable commit
SHA while retaining a human-readable release version comment.

## Status

Accepted

## Context

GitHub Actions references can use mutable major-version tags, release tags, or
branches. A tag can be moved to a different commit after a workflow is
reviewed, changing the code that an existing workflow executes. Marketplace
publisher verification establishes the publisher's identity, but it does not
make a Git ref immutable.

The repository's workflow guidance therefore needs one rule that applies
consistently to GitHub-owned actions, verified Marketplace publishers, and all
other action providers.

## Decision

Every action reference in `.github/workflows/` must use a full-length commit
SHA followed by a comment containing the corresponding release version:

```yaml
- uses: owner/action@0123456789abcdef0123456789abcdef01234567 # v1.2.3
```

The SHA is the security control; the version comment makes updates and review
readable. Publisher verification may inform whether an action is trusted, but
it does not change the required pinning method.

## Alternatives Considered

### Allow major-version tags for GitHub-owned actions

Major tags are convenient to maintain, but they are mutable and can change the
workflow's behavior without a pull request. This is not adopted.

### Allow major-version tags for verified Marketplace publishers

Publisher verification confirms identity rather than ref immutability. It does
not protect a mutable tag from being retargeted or a publisher account from
being compromised. This is not adopted.

### Allow branch or release tags for all other actions

Branches and release tags are also mutable and provide weaker reproducibility
than a commit SHA. This is not adopted.

## Consequences

- Workflow dependencies are reproducible and resistant to mutable-ref changes.
- Updating an action requires resolving and reviewing a new commit SHA.
- Version comments must stay aligned with the pinned release so humans can
  identify the dependency without resolving the SHA.
- Publisher verification no longer creates an exception to the repository-wide
  pinning rule.
