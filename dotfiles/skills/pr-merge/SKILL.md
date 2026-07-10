---
description: A skill used to take a Pull Request all the way to merged. It resolves Copilot Code Review feedback in a loop, marks the PR ready for review, applies the `self approval` label, waits for approval and CI, and performs a squash merge. This also applies when `/pr merge` is invoked.
name: pr-merge
---

# pr-merge

## Overview

This skill takes one or more Pull Requests from "ready for final review" to
"merged". For each PR, it repeatedly runs `pr-fix` and requests a Copilot Code
Review until there are no unresolved findings. It then marks the PR ready,
applies the `self approval` label, waits for approval and CI, and squash
merges it.

The PR head stays in its own `gh-qwt` worktree throughout review, CI, and the
merge request. After GitHub confirms the merge, the skill removes the clean
worktree and its local branch through `gh-qwt`, then deletes the head remote
branch explicitly.

## When to use

- When `/pr-merge` is invoked
- When asked to merge a PR (or several PRs) once review is clean, for example
  "merge PR #42 once it's ready" or "run these PRs through to merge"

## Usage

```text
/pr-merge <PR number> [<PR number> ...]
```

- One or more PR numbers, separated by spaces
- Example: `/pr-merge 12 34`
- PRs are processed one at a time, in the order given

## Workspace rules

- Resolve the base repository for each PR and pass it explicitly as
  `-R <base-owner>/<base-repo>` to every `gh pr` command.
- `pr-fix` owns preparation of the PR head worktree. Its `gh-qwt` contract
  applies to every retry: no `git switch`, `git checkout`, normal-clone
  fallback, or `git worktree`.
- Resolve the head repository, head branch, and head SHA again before cleanup
  with `gh pr view <PR> -R <base-repository> --json
  headRepository,headRefName,headRefOid`.
- Use `gh qwt path <head-owner>/<head-repo>/<head-branch>` to locate the
  worktree. Never infer its path from the current directory.
- Do not use `gh qwt remove --force`. After a confirmed merge,
  `gh qwt remove --delete-branch` is the required, safe cleanup operation:
  it removes the clean worktree before deleting its now-unchecked-out local
  branch.

## Procedure (per PR)

Treat steps 1 through 5 below as a single retry loop, capped at **10
iterations**. Two conditions send control back to the top of the loop;
everything else either continues normally or stops and reports (see
"Retryable vs. non-retryable failures").

### Step 1: Resolve Copilot Code Review feedback

1. Run `/pr-fix all <PR number>`. It provisions or reuses the PR head qwt
   worktree, resolves merge conflicts, CI failures, and review feedback there.
2. Request a review from Copilot Code Review:
   - Get the PR node ID:

     ```bash
     gh pr view <PR_NUMBER> -R <base-repository> --json id -q .id
     ```

   - Request the review:

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
3. Wait for the review to complete: poll once per minute, up to 30 minutes,
   for a review from `copilot-pull-request-reviewer` whose `submittedAt` is
   after the request was sent. Use
   `gh pr view <PR_NUMBER> -R <base-repository> --json latestReviews`.
4. Count the unresolved Copilot Code Review findings:
   - Paginate `reviewThreads(first: 100, after: $cursor)`, following
     `pageInfo { hasNextPage endCursor }` until `hasNextPage` is `false`.
   - For each thread, check `isResolved` and the login of the thread's first
     comment author.
   - Count threads where `isResolved` is `false` and the author is
     `copilot-pull-request-reviewer`.
5. If that count is greater than 0, go back to the top of the loop.

### Step 2: Mark the PR ready for review

- Run `gh pr ready <PR_NUMBER> -R <base-repository>`.
- This is idempotent and safe to run again if the loop repeats.

### Step 3: Apply the `self approval` label

- Run `gh pr edit <PR_NUMBER> -R <base-repository> --add-label "self approval"`.
- The label is expected to already exist in the repository. If `gh` reports
  that it does not exist, stop processing this PR immediately and report the
  error. Do not create the label or retry; another loop iteration cannot fix
  it.

### Step 4: Wait for bot approval

- Immediately after applying the label, record the current time.
- Poll once per minute, up to **3 minutes** (3 checks), for a review with
  `state: APPROVED` whose `submittedAt` is after the recorded time. Use
  `gh pr view <PR_NUMBER> -R <base-repository> --json reviews` or
  `latestReviews`.
- If no approval appears within 3 minutes, stop processing this PR immediately
  and report that the self-approval automation is likely not configured or not
  running. Do not retry; this short timeout intentionally surfaces that case
  quickly.

### Step 5: Wait for CI to go green and re-check mergeability

- Poll once per minute, up to 30 minutes, checking both:
  - `gh pr checks <PR_NUMBER> -R <base-repository> --required` for CI status.
  - `gh pr view <PR_NUMBER> -R <base-repository> --json
    mergeable,mergeStateStatus,headRefOid` for merge-conflict status and head
    changes.
- If `mergeable` is `CONFLICTING`, go back to the top of the loop. `pr-fix`
  resolves conflicts first.
- If any required check's bucket is `fail`, go back to the top of the loop.
  `pr-fix` will attempt to fix the CI failure.
- If 30 minutes pass without reaching a fully green state and without either
  condition above appearing, such as checks stuck in `pending`, stop
  processing this PR and report the timeout.
- If every required check is `pass` or `skipping` and `mergeable` shows no
  conflicts, exit the loop and proceed to Step 6.

### Step 6: Squash merge, then clean up the qwt branch workspace

1. Retrieve the PR head repository, branch, and SHA again. Stop if the head
   repository is missing or the PR head changed since the final successful
   CI/mergeability check.
2. Resolve the explicit qwt worktree path. Verify all of the following:
   - The path exists and its current branch is the PR head branch.
   - `git -C <target> status --porcelain` is empty.
   - After fetching `origin/<head-branch>`, the local `HEAD`, the
     `origin/<head-branch>` SHA, and the PR `headRefOid` are identical.
3. Merge with the checked SHA, without `--delete-branch`:

   ```bash
   gh pr merge <PR_NUMBER> -R <base-repository> --squash \
     --match-head-commit <head-ref-oid>
   ```

4. Confirm that the PR is merged before cleanup. If the merge command fails or
   the PR remains open, leave the worktree intact and report this PR as
   failed.
5. Remove the clean worktree and its local branch:

   ```bash
   (
     cd "$(gh qwt root)" &&
     gh qwt remove <head-owner>/<head-repo>/<head-branch> --delete-branch
   )
   ```

   The command must run outside every qwt repository. Inside a qwt worktree,
   `gh qwt remove` treats its argument as a branch name rather than an
   explicit `owner/repo/branch` spec. Do not pass `--force`. If the worktree
   cannot be removed, the PR is already merged; report a cleanup warning with
   the remaining path instead of reporting a failed merge.
6. Delete the head branch from its own repository, including for fork PRs:

   ```bash
   qwt_repo="$(gh qwt path <head-owner>/<head-repo>)"
   if remote_ref="$(git -C "$qwt_repo" ls-remote origin \
     "refs/heads/<head-branch>")"; then
     if [ -n "$remote_ref" ]; then
       remote_oid="${remote_ref%%[[:space:]]*}"
       if [ "$remote_oid" = "<head-ref-oid>" ]; then
         git -C "$qwt_repo" \
           push --force-with-lease="refs/heads/<head-branch>:<head-ref-oid>" \
           origin --delete <head-branch>
       fi
     fi
   fi
   ```

   First distinguish a missing remote ref from an `ls-remote` authentication
   or network failure; a failed `ls-remote` is a cleanup warning, while a
   successful empty result is successful cleanup. If `remote_oid` differs
   from the verified `<head-ref-oid>`, do not run the push: report a cleanup
   warning because someone updated the branch after the merge check. Run the
   lease-protected deletion only when the OIDs match. If it fails, report a
   cleanup warning but retain the merged PR result. The lease is a race guard,
   not permission to force-update a branch.

## Retryable vs. non-retryable failures

| Condition | Behavior |
| --- | --- |
| Unresolved Copilot Code Review findings (Step 1) | Retryable — return to Step 1 |
| Merge conflict detected (Step 5) | Retryable — return to Step 1 |
| CI failure detected (Step 5) | Retryable — return to Step 1 |
| Missing `self approval` label (Step 3) | Not retryable — stop and report |
| Bot-approval timeout, 3 minutes (Step 4) | Not retryable — stop and report |
| Review-completion timeout, 30 minutes (Step 1) | Not retryable — stop and report |
| CI/mergeability-wait timeout, 30 minutes (Step 5) | Not retryable — stop and report |
| Dirty, missing, or out-of-date qwt worktree (Step 6) | Not retryable — stop and report |
| Merge request fails or PR remains open (Step 6) | Not retryable — stop and report |
| Loop exceeds 10 iterations | Not retryable — stop and report |

Because `gh pr ready` and `gh pr edit --add-label` are idempotent, and this
repository's branch protection has `dismiss_stale_reviews_on_push: false`, an
approval obtained on an earlier iteration is not dismissed by later commits
from a conflict or CI fix. Re-running Steps 2 through 4 on a later iteration
is therefore safe, and Step 4 typically resolves immediately because the
earlier approval remains valid.

## Processing multiple PRs

- Run the full per-PR procedure above for each PR number in order.
- If a PR fails or times out, record the reason, skip it, and continue with
  the next PR. Do not stop the whole batch.
- After all PRs have been processed, report a summary listing each merged PR
  URL or its failure reason.

## Constraints

- Poll every waiting step once per minute.
- Time out review completion and CI/mergeability waits after 30 minutes, and
  bot approval after 3 minutes.
- Limit the retry loop to 10 iterations per PR.
- Never auto-create the `self approval` label. A missing label is a hard error
  for that PR.
- The approval automation itself is outside this skill's scope; this skill
  only waits for its result.
- Do not force-push branch updates unless explicitly instructed. The
  lease-protected deletion in Step 6 is the sole exception: it deletes only a
  remote ref that still equals the verified PR head SHA.
- Only use squash merges, matching this repository's merge strategy settings.

## Output

- For each PR: the merged PR URL on success, or the failure reason and step on
  failure.
- A final summary across all given PRs.
