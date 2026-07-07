---
description: A skill used to take a Pull Request all the way to merged. It resolves Copilot Code Review feedback in a loop, marks the PR ready for review, applies the `self approval` label, waits for approval and CI, and performs a squash merge. This also applies when `/pr merge` is invoked.
name: pr-merge
---

# pr-merge

## Overview

This is a skill for taking one or more Pull Requests from "ready for final review" all the way to "merged". For each PR, it repeatedly runs the `pr-fix` skill and requests a review from Copilot Code Review until there are no unresolved findings, then takes the PR out of Draft, applies the `self approval` label, waits for the pre-existing approval automation and for CI to go green, and finally performs a squash merge.

## When to use

- When `/pr-merge` is invoked
- When asked to merge a PR (or several PRs) once review is clean, for example "merge PR #42 once it's ready" or "run these PRs through to merge"

## Usage

```
/pr-merge <PR number> [<PR number> ...]
```

- One or more PR numbers, separated by spaces
- Example: `/pr-merge 12 34`
- PRs are processed one at a time, in the order given

## Procedure (per PR)

Treat steps 1 through 5 below as a single retry loop, capped at **10 iterations**. Two conditions send control back to the top of the loop; everything else either continues normally or stops and reports (see "Retryable vs. non-retryable failures").

### Step 1: Resolve Copilot Code Review feedback

1. Run `/pr-fix all <PR number>` (fixes merge conflicts, CI failures, and review feedback together)
2. Request a review from Copilot Code Review, using the same GraphQL mutation as `pr-fix`:
   - Get the PR node ID: `gh pr view <PR_NUMBER> --json id -q .id`
   - Request the review:
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
3. Wait for the review to complete: poll once per minute, up to 30 minutes, for a review from `copilot-pull-request-reviewer` whose `submittedAt` is after the request was sent (check with `gh pr view <PR_NUMBER> --json latestReviews`)
   - If 30 minutes pass with no review appearing, stop processing this PR and report the timeout (not retryable)
4. Count the unresolved findings left by Copilot Code Review:
   - Paginate `reviewThreads(first: 100, after: $cursor)` (same pattern as `pr-fix`'s feedback mode), following `pageInfo { hasNextPage endCursor }` until `hasNextPage` is `false`
   - For each thread, check `isResolved` and the login of the thread's first comment author
   - Count the threads where `isResolved` is `false` and the comment author is `copilot-pull-request-reviewer`
5. If that count is greater than 0, go back to the top of the loop (Step 1)

### Step 2: Mark the PR ready for review

- `gh pr ready <PR number>`
- Idempotent — safe to run again if the loop repeats

### Step 3: Apply the `self approval` label

- `gh pr edit <PR number> --add-label "self approval"`
- The label is expected to already exist in the repository. If `gh` reports that the label does not exist, stop processing this PR immediately and report the error. Do not create the label, and do not retry — this is not something another loop iteration can fix.

### Step 4: Wait for bot approval

- Immediately after applying the label, record the current time
- Poll once per minute, up to **3 minutes** (3 checks), for a review with `state: APPROVED` whose `submittedAt` is after the recorded time (check with `gh pr view <PR number> --json reviews` or `latestReviews`)
  - This repository already has a separate, pre-existing automation that approves PRs labeled `self approval`; this skill only waits for its result and does not build or configure that automation
- If no approval appears within 3 minutes, stop processing this PR immediately and report that the self-approval automation is likely not configured or not running. Do not retry — this short timeout is intentional, to surface that case quickly rather than waiting the full 30 minutes used elsewhere.

### Step 5: Wait for CI to go green (and re-check mergeability)

- Poll once per minute, up to 30 minutes, checking both:
  - `gh pr checks <PR number> --required` for CI status
  - `gh pr view <PR number> --json mergeable,mergeStateStatus` for merge-conflict status
- If `mergeable` is `CONFLICTING`, go back to the top of the loop (Step 1) — `/pr-fix all` resolves conflicts as its first phase
- If any required check's bucket is `fail`, go back to the top of the loop (Step 1) — `/pr-fix all` will attempt to fix the CI failure
- If 30 minutes pass without reaching a fully green state and without either condition above appearing (for example, checks stuck in `pending`), stop processing this PR immediately and report the timeout (not retryable)
- If every required check is `pass` (or `skipping`) and `mergeable` shows no conflicts, exit the loop and proceed to Step 6

### Step 6: Squash merge

- `gh pr merge <PR number> --squash --delete-branch`

## Retryable vs. non-retryable failures

| Condition | Behavior |
| --- | --- |
| Unresolved Copilot Code Review findings (Step 1) | Retryable — back to Step 1 |
| Merge conflict detected (Step 5) | Retryable — back to Step 1 |
| CI failure detected (Step 5) | Retryable — back to Step 1 |
| Missing `self approval` label (Step 3) | Not retryable — stop and report |
| Bot-approval timeout, 3 minutes (Step 4) | Not retryable — stop and report |
| Review-completion timeout, 30 minutes (Step 1) | Not retryable — stop and report |
| CI/mergeability-wait timeout, 30 minutes (Step 5) | Not retryable — stop and report |
| Loop exceeds 10 iterations | Not retryable — stop and report |

Because `gh pr ready` and `gh pr edit --add-label` are idempotent, and this repository's branch protection has `dismiss_stale_reviews_on_push: false`, an approval obtained on an earlier iteration is not dismissed by later commits (from a conflict or CI fix made on a later iteration). Re-running Steps 2–4 on a later iteration is therefore safe, and Step 4 in particular typically resolves immediately without any real waiting, since the earlier approval is still valid.

## Processing multiple PRs

- Run the full per-PR procedure above for each PR number given, in order
- If a PR fails or times out (per the table above), record the reason, skip it, and continue with the next PR number — do not stop the whole batch
- After all PR numbers have been processed, report a summary listing, for each PR, either the merged PR's URL or the reason it was not merged

## Constraints

- Polling interval for every waiting step is 1 minute
- Timeouts: 30 minutes for the review-completion wait (Step 1) and the CI/mergeability wait (Step 5); 3 minutes for the bot-approval wait (Step 4)
- Maximum 10 iterations of the retry loop per PR
- Never auto-create the `self approval` label — treat a missing label as a hard error for that PR
- Building or configuring the approval automation itself is out of scope for this skill; it only waits for the existing mechanism
- Do not force-push unless explicitly instructed (same constraint as `pr-fix`)
- Only use squash merges, matching this repository's merge strategy settings (`allow_squash_merge` only)

## Output

- For each PR: the merged PR's URL on success, or the failure reason (which step, and why) if it could not be merged
- A final summary listing successes and failures across all PR numbers given
