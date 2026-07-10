---
description: A skill used when fixing a Pull Request. It handles CI failures, review feedback, and merge conflicts. This also applies when `/pr fix`, `/pr fix all`, `/pr fix ci`, `/pr fix feedback`, or `/pr fix conflicts` is invoked.
name: pr-fix
---

# pr-fix

This skill brings a Pull Request into a mergeable state from its own
`gh-qwt` worktree.

## Usage

Invoke it with a PR number and an optional mode:

```text
/pr fix #42              # Fix everything (conflicts -> ci -> feedback)
/pr fix all #42          # Same as above (explicit mode)
/pr fix ci #42           # Fix CI failures only
/pr fix feedback #42     # Handle review comments only
/pr fix conflicts #42    # Resolve merge conflicts only
```

## Prepare the PR worktree

Run this once before the selected mode. It is required even when the invoking
directory is a different worktree.

1. Confirm that `gh qwt --help` succeeds. Do not use `git switch`,
   `git checkout`, `git worktree`, or a normal-clone fallback.
2. Resolve the base repository from the current GitHub repository context, and
   retrieve the PR explicitly with:

   ```bash
   gh pr view <PR_NUMBER> -R <base-owner>/<base-repo> \
     --json headRefName,headRepository,isCrossRepository,baseRefName,url
   ```

3. Stop and report the error if `headRepository` is null, which commonly
   means a fork was deleted. Do not create a replacement branch in the base
   repository.
4. Set the target repository to `headRepository.nameWithOwner` and the target
   branch to `headRefName`. This is the branch that will receive fixes. Keep
   the base repository separately for PR API commands.
5. Resolve the expected target path with
   `gh qwt path <head-owner>/<head-repo>/<head-branch>`.
   - If that worktree exists, verify that
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
     `gh qwt get <head-owner>/<head-repo> --branch <head-branch>`.
   - Resolve the path again with `gh qwt path` and verify both the directory
     and its checked-out branch.
6. Fetch `origin --prune` from the resolved target and confirm that
   `origin/<head-branch>` exists. Compare it with local `HEAD` before
   editing:
   - If they match, continue.
   - If the clean local branch is behind, run
     `git -C <target> merge --ff-only origin/<head-branch>`.
   - If local `HEAD` is ahead or diverged, stop rather than overwriting,
     force-pushing, or working on a stale PR head.
7. If `gh-qwt` reports a slash-prefix path collision, cannot find the remote
   branch, or cannot create the worktree, stop and report the qwt error. Do
   not fall back to a branch checkout.
8. Inspect `git -C <target> status --porcelain` before changing files. If an
   existing PR worktree has uncommitted changes, stop and ask the user how to
   handle them; never use `gh qwt remove --force`.
9. Verify push access to the head repository before making fixes, for example
   with `git -C <target> push --dry-run origin <head-branch>`. For a fork PR,
   this checks access to the fork rather than assuming the base repository is
   writable. Stop if it is rejected.

All Git commands that inspect, modify, test, commit, or push the PR must use
the target path. Use `git -C <target> ...` or an equivalent command whose
working directory is exactly the target worktree. All `gh pr` calls must use
`-R <base-owner>/<base-repo>` so they continue to address the PR when the
head is a fork.

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
  for the base repository and fetch `upstream/<base-ref>`.
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
- Once all responses are complete, request a review from Copilot Code Review.
  - Get the PR node ID with
    `gh pr view <PR_NUMBER> -R <base-repository> --json id -q .id`.
  - Use the retrieved node ID to request a review:

    ```bash
    gh api graphql -f query='
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

### Local review before pushing

- Before committing and pushing changes, run a local code review using a
  sub-agent with the `code-review` agent type.
- Confirm there are no significant issues in the local review before
  committing and pushing.

### Update the PR title and description

- After making fixes and pushing, update the PR title and description so they
  accurately reflect the current state of the changes.
- Before updating, always retrieve the current title and description with
  `gh pr view <PR_NUMBER> -R <base-repository>` and edit based on that
  content, since someone else may have already updated it.
- Use `gh pr edit <PR_NUMBER> -R <base-repository> --title` and
  `gh pr edit <PR_NUMBER> -R <base-repository> --body` to apply the updates.

## Constraints

- Keep the PR head worktree after the skill completes so a later `pr-fix` or
  `pr-merge` invocation can reuse it.
- Make one commit per logical fix and use a clear message.
- Do not force-push unless explicitly instructed.
- Do not use a branch checkout, a normal-clone `git worktree`, or a qwt force
  removal to work around a workspace error.
