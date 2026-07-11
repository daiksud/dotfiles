# ADR 0012: Require immutable SHA pins for GitHub Actions

Require remote GitHub Actions references to use immutable commit SHAs, with
image digests for Docker actions and path references for local code.

## Status

Accepted

## Context

Remote GitHub Actions references can use mutable major-version tags, release
tags, or branches. A tag can be moved to a different commit after a workflow
is reviewed, changing the code that an existing workflow executes. Marketplace
publisher verification establishes the publisher's identity, but it does not
make a Git ref immutable.

The repository's workflow guidance therefore needs one rule that applies
consistently to GitHub-owned actions, verified Marketplace publishers, and all
other remote action providers. It also needs to explain the immutable form for
Docker actions and the cases where a commit ref is not part of the syntax, such
as local actions and local reusable workflows.

## Decision

Every remote repository action and reusable workflow reference in
`.github/workflows/` must use a full-length commit SHA followed by a comment
containing the corresponding release version:

```yaml
- uses: owner/action@0123456789abcdef0123456789abcdef01234567 # v1.2.3
```

The SHA is the security control; the version comment makes updates and review
readable. Publisher verification may inform whether an action is trusted, but
it does not change the required pinning method.

Local actions and local reusable workflows referenced with `./...` do not have
a ref to pin. They remain tied to the checked-out repository contents and are
subject to normal code review. Docker actions referenced with `docker://...`
must use an immutable image digest rather than a mutable tag.

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

### Apply commit-SHA syntax to local or Docker actions

Local references do not accept a commit ref, and Docker actions use image
references rather than Git refs. This is not adopted; local references remain
path-based and Docker actions use immutable image digests.

## Consequences

- Workflow dependencies are reproducible and resistant to mutable-ref changes.
- Updating a remote repository action or reusable workflow requires resolving
  and reviewing a new commit SHA.
- Version comments must stay aligned with the pinned release so humans can
  identify the dependency without resolving the SHA.
- Publisher verification no longer creates an exception to the repository-wide
  pinning rule for remote repository references.
- Local actions and reusable workflows require code review instead of ref
  pinning, and Docker actions require digest updates.
