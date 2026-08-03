---
name: pr-fix
description: Bring an existing GitHub Pull Request into a mergeable state from an isolated gh-qwt worktree. Use when asked to fix a PR, resolve merge conflicts, repair failing CI checks, address unresolved review feedback, or run all of these workflows in sequence. Accept a PR number and an optional all, ci, feedback, or conflicts mode.
---

# pr-fix

Bring a Pull Request into a mergeable state from its own `gh-qwt` worktree.

## Inputs

Accept a PR number and an optional mode:

- Omit the mode or use `all` to fix everything in this order: conflicts, CI,
  then feedback.
- Use `ci` to fix CI failures only.
- Use `feedback` to handle review comments only.
- Use `conflicts` to resolve merge conflicts only.

## Prepare the PR worktree

Run this once before the selected mode. It is required even when the invoking
directory is a different worktree.

1. Confirm that `gh qwt --help` succeeds. Do not use `git switch`,
   `git checkout`, `git worktree`, or a normal-clone fallback.
2. Resolve the selected base remote's expanded fetch URL through GitHub. Record
   its canonical repository URL, lowercase host, canonical `nameWithOwner`,
   and default branch. Define `<base-repository>` as the host-qualified
   `<base-host>/<base-owner>/<base-repo>`. Do not infer `github.com` from an
   unqualified repository name, and stop if any part of the base identity
   cannot be verified.
3. Retrieve the PR explicitly from that base identity with:

   ```bash
   gh pr view <PR_NUMBER> -R <base-repository> \
     --json headRefName,headRepository,isCrossRepository,baseRefName,url
   ```

4. Stop and report the error if `headRepository` is null, which commonly
   means a fork was deleted. Do not create a replacement branch in the base
   repository.
5. Resolve the returned head repository through GitHub on the base host. Record
   its canonical repository URL, lowercase host, and canonical
   `nameWithOwner`; stop if any part cannot be verified. Set the target branch
   to `headRefName`. Use this head identity for all qwt and Git operations, and
   keep `<base-repository>` separately for PR API commands.
6. Calculate the qwt repository and target paths with
   `gh qwt path <head-owner>/<head-repo>` and
   `gh qwt path <head-owner>/<head-repo>/<head-branch>`. Treat the qwt
   repository as existing only when `<qwt-repository>/.bare` is a directory.
   If the calculated repository path is occupied but `.bare` is absent, stop
   and report a repository-path collision; do not run `get` inside it.
7. If the qwt repository exists, guard its identity before listing, fetching,
   adding to, inspecting, or reusing it:
   - Read the expanded fetch URL for `origin` directly from
     `<qwt-repository>/.bare` and resolve that URL through GitHub.
   - Require both its canonical repository URL and its full
     `<lowercase-host>/<canonical-owner>/<canonical-repo>` identity to equal
     the recorded head repository identity.
   - Stop if either side cannot be verified or differs. Do not fetch, rewrite
     `origin`, add a worktree, or reuse the repository. Report the host
     collision and require a separately selected qwt root or manual
     resolution.
8. Provision or reuse the target only after the identity guard permits it:
   - When the qwt repository exists, run
     `gh qwt list <head-owner>/<head-repo>/<head-branch> --exact --full-path`
     without output filtering and require it to succeed. Treat the target as
     registered only when at least one stdout line equals the calculated target
     path byte-for-byte; ignore every other line. If no exact line exists but
     the path is occupied by a file, directory, or link, stop and report a path
     collision. When the qwt repository is missing, likewise stop before
     `get` if its calculated target path is already occupied.
   - If that worktree is exactly registered, verify that
     `git -C <target> branch --show-current` equals the PR head branch.
     Inspect `git -C <target> status --porcelain`; if it is not empty, stop
     and ask the user how to handle the existing changes.
   - If the qwt repository exists but the worktree does not, first refresh
     its cached branch refs with
     `git -C "$(gh qwt path <head-owner>/<head-repo>)" fetch origin --prune`,
     then create the worktree with
     `gh qwt add --repo <head-owner>/<head-repo> <head-branch>`.
   - If the qwt repository does not exist, clone it directly into the PR head
     branch with
     `gh qwt get --host <head-host> --branch <head-branch> <head-owner>/<head-repo>`.
     Immediately run the identity guard against the new bare `origin`; stop
     before inspecting or reusing the target if verification fails.
   - After every `get` or `add`, resolve the path again and repeat the exact
     unfiltered `gh qwt list` check. Require the calculated target path to
     appear byte-for-byte, then verify both the directory and its checked-out
     branch. Stop if registration is missing; never substitute an occupied
     unregistered path.
9. Fetch `origin --prune` from the resolved target and confirm that
   `origin/<head-branch>` exists. Compare it with local `HEAD` before
   editing:
   - If they match, continue.
   - If the clean local branch is behind, run
     `git -C <target> merge --ff-only origin/<head-branch>`.
   - If local `HEAD` is ahead or diverged, stop rather than overwriting,
     force-pushing, or working on a stale PR head.
10. If `gh-qwt` reports a slash-prefix path collision, cannot find the remote

    branch, or cannot create the worktree, stop and report the qwt error. Do
    not fall back to a branch checkout.
11. Inspect `git -C <target> status --porcelain` before changing files. If an

    existing PR worktree has uncommitted changes, stop and ask the user how to
    handle them; never use `gh qwt remove --force`.
12. Verify push access to the head repository before making fixes, for example

    with `git -C <target> push --dry-run origin <head-branch>`. For a fork PR,
    this checks access to the fork rather than assuming the base repository is
    writable. Stop if it is rejected.

All Git commands that inspect, modify, test, commit, or push the PR must use
the target path. Use `git -C <target> ...` or an equivalent command whose
working directory is exactly the target worktree. All `gh pr` calls must use
`-R <base-repository>` so they continue to address the canonical base host and
repository when the head is a fork.

## Modes

### ci — Fix CI failures

- Retrieve CI status with `gh pr checks <PR_NUMBER> -R <base-repository>`.
- If any checks are failing, inspect their logs and identify the root cause.
- Apply fixes in the target worktree, run the smallest relevant local
  validation, and repeat until all CI checks pass.
- Commit and push from the target worktree once CI is green.
- If the CI failures cannot be resolved after 3 attempts, stop the work and
  report the issue.

### conflicts — Resolve merge conflicts

- Retrieve `baseRefName` and the base repository during workspace preparation.
- Fetch the PR base into the target worktree. For a same-repository PR, use
  `origin/<base-ref>`. For a fork PR, configure or reuse an `upstream` remote
  for the base repository and fetch `upstream/<base-ref>`. Before fetching a
  newly configured or reused `upstream`, resolve its expanded fetch URL
  through GitHub and require its canonical URL and full host/owner/repo
  identity to equal the recorded base identity. Stop on an unverifiable or
  mismatched remote instead of rewriting it.
- Merge the fetched base into the target branch and resolve every conflict
  while preserving the intent of the PR changes. Prefer a merge over a rebase
  so the resulting branch can be pushed without force-pushing.
- Identify all conflicted files. Unless the base-branch change is obviously
  correct, resolve each conflict deliberately rather than accepting one side
  wholesale.
- Commit the resolution with a clear message and push from the target
  worktree.

### feedback — Handle review comments

- Retrieve all unresolved review comments from the base repository.
  - Retrieve all replies to review comments as well.
  - Run every GraphQL query against `<base-host>` explicitly.
  - When retrieving review threads via GraphQL, use
    `reviewThreads(first: 100, after: $cursor)` and inspect
    `pageInfo { hasNextPage endCursor }`.
  - If `hasNextPage` is `true`, fetch the next page with
    `after: <endCursor>` and repeat until `hasNextPage` becomes `false`.
- If a comment thread contains a user reply stating that it will not be
  addressed, such as "対応しない", do not change the code for that comment and
  skip the validity evaluation below. Append to the PR body that the comment
  will not be addressed, together with the user's reason.
- For each remaining comment, evaluate whether the feedback is valid.
  - **Valid** — Apply the proposed fix or improvement in the target worktree.
    If the feedback describes a specific case that causes an error or bug, use
    TDD:
    1. Write a unit test that reproduces the reported case.
    2. Confirm the unit test fails before making code changes.
    3. Fix the code until the unit test passes.
  - **Not valid / not applicable** — Do not change the code; prepare a reply
    explaining why.
- After pushing, reply to each comment from the base repository, prefixing
  every comment body with `:robot:`.
  - If fixed: Explain the changes that were made.
  - If not fixed: Explain why it was judged not applicable.
  - If the user decided not to address it: State that it will not be addressed
    and that the reason is recorded in the PR body.
- After sending replies, resolve the review comment threads.
- Once all responses are complete, determine whether Copilot Code Review is
  enabled for the PR base branch before requesting a review:
  - After storing `baseRefName` in `base_ref`, URL-encode it as one path
    segment, for example:

    ```bash
    encoded_base_ref="$(python3 -c 'import sys; from urllib.parse import quote; print(quote(sys.argv[1], safe=""))' "$base_ref")"
    ```

    Retrieve the active rules that apply to it with
    `gh api --hostname <base-host>
    "repos/<base-owner>/<base-repo>/rules/branches/${encoded_base_ref}"`.
  - If the request fails, stop and report that Copilot Code Review availability
    could not be determined. Do not guess from local repository files or try
    the review request anyway.
  - If the response contains no rule whose `type` is
    `copilot_code_review`, report that Copilot Code Review is not enabled for
    the base branch and skip the review request.
- When the effective rules include `copilot_code_review`, request a review.
  - Get the PR node ID with
    `gh pr view <PR_NUMBER> -R <base-repository> --json id -q .id`.
  - Use the retrieved node ID to request a review:

    ```bash
    gh api graphql --hostname <base-host> -f query='
    mutation {
      requestReviews(input: {
        pullRequestId: "<PR_NODE_ID>",
        botIds: ["BOT_kgDOCnlnWA"],
        union: true
      }) {
        pullRequest {
          reviewRequests(first: 5) {
            nodes {
              requestedReviewer {
                __typename
                ... on Bot { login }
              }
            }
          }
        }
      }
    }'
    ```

  - `BOT_kgDOCnlnWA` is the GraphQL node ID for
    `copilot-pull-request-reviewer`.
  - Do not use `gh pr edit --add-reviewer`: GitHub rejects bots as
    non-collaborators through that REST API.

### (default / all) — Fix everything

If no mode is specified, or if `all` is specified, run the three modes in
order: **conflicts -> ci -> feedback**.

Conflicts must be resolved first for CI to run correctly.

## Common steps (all modes)

### Perform a local review before pushing

- Before committing and pushing changes, perform an independent local code
  review. Use an available dedicated review skill or review subagent when the
  host provides one. Otherwise, perform a distinct review pass over the full
  diff, checking correctness, regressions, security, and test coverage
  separately from implementation.
- Do not commit or push until the review has no unresolved significant issues.

### Update the PR title and description

- After making fixes and pushing, update the PR title and description so they
  accurately reflect the current state of the changes.
- Before updating, always retrieve the current title and description with
  `gh pr view <PR_NUMBER> -R <base-repository>` and edit based on that
  content, since someone else may have already updated it.
- Use `gh pr edit <PR_NUMBER> -R <base-repository> --title` and
  `gh pr edit <PR_NUMBER> -R <base-repository> --body` to apply the updates.

## Constraints

- Keep the PR head worktree after the skill completes so a later use of
  `pr-fix` or `pr-merge` can reuse it.
- Make one commit per logical fix and use a clear message.
- Do not force-push unless explicitly instructed.
- Do not use a branch checkout, a normal-clone `git worktree`, or a qwt force
  removal to work around a workspace error.

## Output

- Report whether Copilot Code Review was requested or skipped because the
  effective base-branch rules do not enable it.
- Report any availability-query failure as a blocking error rather than
  treating Copilot Code Review as enabled or disabled.
