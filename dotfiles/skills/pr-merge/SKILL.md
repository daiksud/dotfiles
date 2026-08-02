---
name: pr-merge
description: Take one or more GitHub Pull Requests through final review, conditional approval, required CI, squash merge, and safe gh-qwt cleanup. Use when asked to merge PRs once ready, monitor them through merge, loop through enabled Copilot Code Review feedback with the pr-fix skill, apply self approval only when required, wait for required checks, or process multiple PRs to completion.
---

# pr-merge

## Overview

Take one or more Pull Requests from "ready for final review" to "merged". For
each PR, repeatedly use `pr-fix` and, when the base branch enables it, request
a Copilot Code Review until there are no unresolved findings. Then mark the PR
ready, request self approval only when GitHub reports that review is required,
wait for CI, and squash merge it.

Keep the PR head in its own `gh-qwt` worktree throughout review, CI, and the
merge request. After GitHub confirms the merge, remove the clean worktree and
its local branch through `gh-qwt`, then delete the head remote branch
explicitly.

## Inputs

- Require one or more PR numbers.
- Process PRs one at a time in the order given.

## Workspace rules

- Resolve the selected base remote's expanded fetch URL through GitHub for each
  PR. Record its canonical repository URL, lowercase host, and canonical
  `nameWithOwner`; define `<base-repository>` as the host-qualified
  `<base-host>/<base-owner>/<base-repo>`. Stop if the base identity cannot be
  verified, and pass `-R <base-repository>` to every `gh pr` command.
- `pr-fix` owns preparation of the PR head worktree. Its `gh-qwt` contract
  and full canonical head repository identity guard apply to every retry: no
  `git switch`, `git checkout`, normal-clone fallback, or `git worktree`.
- Resolve the head repository, head branch, and head SHA again before cleanup.
  Resolve the returned head repository through GitHub on the base host and
  record its canonical URL, lowercase host, and canonical `nameWithOwner`.
  Stop if this identity cannot be verified or differs from the head identity
  used by the final `pr-fix` pass.
- Use `gh qwt path <head-owner>/<head-repo>/<head-branch>` to locate the
  worktree. Never infer its path from the current directory.
- Before fetching, reusing, removing, or otherwise operating on the cleanup
  repository, read the expanded `origin` fetch URL directly from its bare Git
  database and resolve it through GitHub. Require both the canonical URL and
  full `<lowercase-host>/<canonical-owner>/<canonical-repo>` identity to equal
  the freshly resolved PR head. Stop before cleanup on an unverifiable or
  mismatched identity; never rewrite `origin` or act on a host-colliding qwt
  path.
- Do not use `gh qwt remove --force`. After a confirmed merge,
  `gh qwt remove --delete-branch` is the required, safe cleanup operation:
  it removes the clean worktree before deleting its now-unchecked-out local
  branch.

## Procedure (per PR)

Treat steps 1 through 5 below as a single retry loop, capped at **10
iterations**. Two conditions send control back to the top of the loop;
everything else either continues normally or stops and reports (see
"Retryable vs. non-retryable failures").

Before the first iteration:

1. Retrieve `baseRefName` for the PR, URL-encode it as one path segment, and
   query the active rules for that branch with
   `gh api --hostname <base-host>
   "repos/<base-owner>/<base-repo>/rules/branches/<encoded-base-ref>"`.
   Stop this PR if the query fails; do not infer availability from local files
   or continue with an assumed setting.
2. Record whether the response contains a rule whose `type` is
   `copilot_code_review`. This per-PR value controls every iteration of the
   Copilot review loop.
3. Initialize persistent per-PR approval state: an unset approval-request
   timestamp and no recorded approved review. Carry both values across every
   retry; never reset them at the top of the loop.

### Step 1: Resolve Copilot Code Review feedback

1. Use the `pr-fix` skill in `all` mode for the PR number. Let it provision or
   reuse the PR head qwt worktree and resolve merge conflicts, CI failures,
   and review feedback there. Retain the canonical head URL and full
   host/owner/repo identity that its guard verifies during the final pass.
2. If the effective rules do not include `copilot_code_review`, record that
   Copilot Code Review is disabled and proceed directly to Step 2. Do not
   request a review, wait for one, or count Copilot findings.
3. When Copilot Code Review is enabled, request a review:
   - Get the PR node ID:

     ```bash
     gh pr view <PR_NUMBER> -R <base-repository> --json id -q .id
     ```

   - Request the review:

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
4. Wait for the review to complete: poll once per minute, up to 30 minutes,
   for a review from `copilot-pull-request-reviewer` whose `submittedAt` is
   after the request was sent. Use
   `gh pr view <PR_NUMBER> -R <base-repository> --json latestReviews`.
5. Count the unresolved Copilot Code Review findings:
   - Run every GraphQL query against `<base-host>` explicitly.
   - Paginate `reviewThreads(first: 100, after: $cursor)`, following
     `pageInfo { hasNextPage endCursor }` until `hasNextPage` is `false`.
   - For each thread, check `isResolved` and the login of the thread's first
     comment author.
   - Count threads where `isResolved` is `false` and the author is
     `copilot-pull-request-reviewer`.
6. If that count is greater than 0, go back to the top of the loop.

### Step 2: Mark the PR ready for review

- Run `gh pr ready <PR_NUMBER> -R <base-repository>`.
- This is idempotent and safe to run again if the loop repeats.

### Step 3: Establish persistent approval state

1. Query `reviewDecision` and the current reviews after the PR is ready.
   - If `reviewDecision` is null or empty, record that approval is not required
     for this iteration and skip both the label request and Step 4.
   - If `reviewDecision` is `APPROVED`, record the valid review identity and
     `submittedAt` in the persistent per-PR state and skip the approval request
     and wait.
   - Otherwise, continue with the approval request. On later iterations,
     retain a recorded approval only while `reviewDecision` remains
     `APPROVED`; clear it when GitHub no longer reports approval.
2. If approval is required, no valid approval exists, and the approval-request
   timestamp is unset,
   record the current time once and run
   `gh pr edit <PR_NUMBER> -R <base-repository> --add-label "self approval"`.
   Keep that timestamp for every later iteration. Do not remove and re-add the
   label or call `--add-label` again to try to retrigger the automation.
3. Only when the label request is needed, expect the label to already exist in
   the repository. If `gh` reports that it does not exist, stop processing
   this PR immediately and report the error. Do not create the label or retry;
   another loop iteration cannot fix it.

### Step 4: Wait for bot approval

- Skip this step when Step 3 found that `reviewDecision` is null or empty, or
  when the persistent state contains an approval that GitHub still reports as
  `APPROVED`.
- Otherwise, poll once per minute for `reviewDecision` and the current reviews.
  When GitHub reports `APPROVED`, require the corresponding newly observed
  review to have `submittedAt` at or after the persistent approval-request
  timestamp, then record its identity and timestamp. If `reviewDecision`
  becomes null or empty, approval is no longer required; record that state and
  proceed.
  Measure the **3-minute** deadline from the one persistent request timestamp,
  not from the start of each iteration. Use
  `gh pr view <PR_NUMBER> -R <base-repository> --json reviewDecision,reviews`
  or include `latestReviews` when identifying the approving review.
- If GitHub still requires review and no approval appears within 3 minutes,
  stop processing this PR immediately and report that the self-approval
  automation is likely not configured or not running. Do not retry; this short
  timeout intentionally surfaces that case quickly.

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

1. Retrieve the PR head repository, branch, and SHA again with
   `gh pr view <PR_NUMBER> -R <base-repository> --json
   headRepository,headRefName,headRefOid`. Resolve the returned head repository
   through GitHub on `<base-host>` and record its canonical URL, lowercase host,
   and canonical `nameWithOwner`. Stop if the head repository or identity is
   missing, the identity differs from the final verified `pr-fix` head, or the
   PR head changed since the final successful CI/mergeability check.
2. Calculate the qwt repository and explicit worktree paths. Require
   `<qwt-repository>/.bare` to exist, then run the workspace identity guard
   against the freshly resolved head before reading the target, fetching, or
   performing cleanup. Stop on an unverifiable or mismatched `origin`.
3. Run
   `gh qwt list <head-owner>/<head-repo>/<head-branch> --exact --full-path`
   without output filtering and require it to succeed. At least one stdout
   line must equal the calculated target path byte-for-byte; ignore other
   lines. Stop before reading, fetching, merging, or cleanup if the target is
   not exactly registered, even when a directory occupies that path.
4. Verify all of the following:
   - The path exists and its current branch is the PR head branch.
   - `git -C <target> status --porcelain` is empty.
   - After fetching `origin/<head-branch>`, the local `HEAD`, the
     `origin/<head-branch>` SHA, and the PR `headRefOid` are identical.
5. Merge with the checked SHA, without `--delete-branch`:

   ```bash
   gh pr merge <PR_NUMBER> -R <base-repository> --squash \
     --match-head-commit <head-ref-oid>
   ```

6. Confirm that the PR is merged before cleanup. If the merge command fails or
   the PR remains open, leave the worktree intact and report this PR as
   failed.
7. Remove the clean worktree and its local branch:

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
8. Resolve the remaining qwt bare `origin` through GitHub again after local
   cleanup and require its canonical URL and full host/owner/repo identity to
   still equal the verified head. If the repository is missing or fails this
   guard, do not contact `origin`; report a cleanup warning while retaining the
   successful merge result. Otherwise, delete the head branch from its own
   repository, including for fork PRs:

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
| Effective base-branch rules cannot be retrieved | Not retryable — stop and report |
| Unresolved Copilot Code Review findings (Step 1) | Retryable — return to Step 1 |
| Merge conflict detected (Step 5) | Retryable — return to Step 1 |
| CI failure detected (Step 5) | Retryable — return to Step 1 |
| Missing required `self approval` label (Step 3) | Not retryable — stop and report |
| Required bot-approval timeout, 3 minutes (Step 4) | Not retryable — stop and report |
| Enabled review-completion timeout, 30 minutes (Step 1) | Not retryable — stop and report |
| CI/mergeability-wait timeout, 30 minutes (Step 5) | Not retryable — stop and report |
| Dirty, missing, or out-of-date qwt worktree (Step 6) | Not retryable — stop and report |
| Merge request fails or PR remains open (Step 6) | Not retryable — stop and report |
| Loop exceeds 10 iterations | Not retryable — stop and report |

Keep the approved review identity and timestamp outside the retry loop. Reuse
it only while GitHub continues to report `reviewDecision: APPROVED`; this
prevents a stale review from satisfying a repository that dismisses approvals
after later conflict or CI fixes. Although `gh pr ready` is safe to repeat,
never reset the approval-request timestamp or rely on re-adding the label to
trigger another approval. If an approval becomes stale, the wait remains bound
to the original request and deadline.

## Processing multiple PRs

- Run the full per-PR procedure above for each PR number in order.
- If a PR fails or times out, record the reason, skip it, and continue with
  the next PR. Do not stop the whole batch.
- After all PRs have been processed, report a summary listing each merged PR
  URL or its failure reason.

## Constraints

- Poll every waiting step once per minute.
- Time out enabled review completion and CI/mergeability waits after 30
  minutes, and required bot approval after 3 minutes.
- Limit the retry loop to 10 iterations per PR.
- Never auto-create the `self approval` label. A missing label is a hard error
  only when GitHub reports that review is required and no valid approval
  exists.
- The approval automation itself is outside this skill's scope; this skill
  only waits for its result.
- Do not force-push branch updates unless explicitly instructed. The
  lease-protected deletion in Step 6 is the sole exception: it deletes only a
  remote ref that still equals the verified PR head SHA.
- Only use squash merges, matching this repository's merge strategy settings.

## Output

- For each PR: the merged PR URL on success, or the failure reason and step on
  failure.
- Report when Copilot Code Review or self approval was skipped because the
  repository configuration did not require it.
- A final summary across all given PRs.
