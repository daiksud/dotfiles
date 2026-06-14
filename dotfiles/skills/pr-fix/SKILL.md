---
description: A skill used when fixing a Pull Request. It handles CI failures, review feedback, and merge conflicts. This also applies when `/pr fix`, `/pr fix all`, `/pr fix ci`, `/pr fix feedback`, or `/pr fix conflicts` is invoked.
name: pr-fix
---

# pr-fix

This is a skill for bringing a Pull Request into a mergeable state.

## Usage

Invoke it with a PR number and an optional mode:

```
/pr fix #42              # Fix everything (conflicts → ci → feedback)
/pr fix all #42          # Same as above (explicit mode)
/pr fix ci #42           # Fix CI failures only
/pr fix feedback #42     # Handle review comments only
/pr fix conflicts #42    # Resolve merge conflicts only
```

## Modes

### ci — Fix CI failures

- Retrieve the CI status for the specified PR
- If any checks are failing, inspect the logs and identify the root cause
- Apply fixes iteratively until all CI checks pass
- Commit and push once CI is green
- If the CI failures cannot be resolved after 3 attempts, stop the work and report the issue

### conflicts — Resolve merge conflicts

- Fetch the PR base branch and surface conflicts through a rebase or merge
- Identify all files with conflicts
- Unless the base branch change is obviously correct, resolve each conflict while preserving the intent of the PR changes
- Commit the resolved files with a clear message
- Push the resolved branch

### feedback — Handle review comments

- Retrieve all unresolved review comments on the PR
  - Be sure to retrieve all replies to the review comments as well
  - When retrieving review threads via GraphQL, use `reviewThreads(first: 100, after: $cursor)` and inspect `pageInfo { hasNextPage endCursor }` in the response
  - If `hasNextPage` is `true`, fetch the next page with `after: <endCursor>` and repeat until `hasNextPage` becomes `false`
- For each comment, evaluate whether the feedback is valid:
  - **Valid** — apply the proposed fix or improvement
  - **Not valid / not applicable** — do not change the code; instead, prepare a reply explaining why
- After pushing, reply to each comment describing how it was handled:
  - If fixed: explain the changes that were made
  - If not fixed: explain why it was judged not applicable
- After sending replies, resolve the review comment threads
- Once all responses are complete, request a review from Copilot Code Review
  - Get the PR node ID: `gh pr view <PR_NUMBER> --json id -q .id`
  - Use the retrieved node ID to request a review via a GraphQL mutation:
    ```
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
  - `BOT_kgDOCnlnWA` is the GraphQL node ID for `copilot-pull-request-reviewer`
  - The REST API (`gh pr edit --add-reviewer`) cannot be used because bots are rejected as "not a collaborator"

### (default / all) — Fix everything

If no mode is specified, or if `all` is specified, run the three modes in order: **conflicts → ci → feedback**

Conflicts must be resolved first for CI to run correctly.

## Common steps (all modes)

### Local review before pushing

- Before committing and pushing changes, run a local code review using a sub-agent (the `code-review` agent type)
- Confirm there are no significant issues in the local review before committing and pushing

### Update the PR title and description

- After making fixes and pushing, update the PR title and description so they accurately reflect the current state of the changes
- Before updating, always retrieve the current title and description with `gh pr view <PR_NUMBER>` and edit based on that content, since someone else may have already updated them
- Use `gh pr edit <PR_NUMBER> --title` and `gh pr edit <PR_NUMBER> --body` to apply the updates

## Constraints

- Always work on the PR branch (check out the branch before making changes)
- Make one commit per logical fix and use a clear message
- Do not force-push unless explicitly instructed
