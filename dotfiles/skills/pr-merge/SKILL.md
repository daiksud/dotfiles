---
name: pr-merge
description: Take one or more GitHub Pull Requests through final review, conditional approval, required CI, and squash merge from verified head branches in the invoking checkout. Use when asked to merge one PR, an ordered list of PRs, or all open PRs in the current repository. Accept a PR URL, one or more PR numbers with an optional host-qualified base repository, or all.
---

# pr-merge

## Overview

Take Pull Requests from "ready for final review" to "merged". For each
selected PR, use `pr-fix`, request a Copilot Code Review when the base branch
requires it, wait for approval and CI, then squash merge the verified head
SHA.

A single-PR invocation preserves the existing checkout contract: it operates
in the invoking checkout, requires the exact PR head branch, and does not
switch branches. A batch invocation processes same-repository PRs
sequentially in the invoking checkout. It may switch between clean local
branches, but it never creates a `gh-qw`, Git, or other worktree. It leaves
all processed local branches in place and returns to the branch that was
checked out when the batch started.

## Inputs

Use one of these forms:

- `pr-merge <PR_URL>` — merge one PR identified by its URL.
- `pr-merge <PR_NUMBER> [<base-repository>]` — merge one PR by number.
- `pr-merge <PR_NUMBER> <PR_NUMBER> ... [<base-repository>]` — merge several
  PRs in the order supplied.
- `pr-merge all [<base-repository>]` — snapshot every open PR in the target
  repository and process them in ascending PR-number order.

The optional final `<base-repository>` is a canonical host-qualified identity,
such as `github.com/owner/repo`. When it is omitted for a numeric input or
`all`, resolve the current checkout's expanded `origin` fetch URL through
GitHub and use that repository. Do not infer a base repository from a fork PR
head. A URL identifies its own base repository and is supported for a
single-PR invocation; batch mode uses PR numbers so its target repository is
unambiguous.

`all` cannot be combined with PR numbers or a URL. Reject an ambiguous
trailing repository token, duplicate PR numbers, or inputs that resolve to
different base repositories before starting any branch or GitHub mutation.

## Checkout rules

### Single PR

`pr-fix` owns checkout validation. Its requirements apply before every retry:
the invoking checkout's `origin` must resolve to the PR head repository, its
current branch must equal the PR head branch, and it must be clean before
changes begin.

Resolve the base repository through GitHub for every PR. Record its canonical
URL, lowercase host, canonical `nameWithOwner`, and default branch. Define
`<base-repository>` as the host-qualified
`<base-host>/<base-owner>/<base-repo>` and pass it to every `gh pr` command.

Never create or use `gh qw`, `git worktree`, another checkout, or an automatic
branch switch for a single PR. If the current checkout is not the PR head,
stop and report the canonical head repository URL and branch.

### Batch

Batch mode is enabled when the input contains multiple PR numbers or `all`.
Before resolving the queue:

1. Require a Git checkout with a clean working tree, a non-detached `HEAD`, no
   unresolved merge or rebase, and a resolvable current branch. Save that
   starting branch for restoration.
2. Resolve the target base repository and require the invoking checkout's
   expanded `origin` fetch URL to equal that canonical base repository. This
   same-repository requirement intentionally excludes fork PR heads.
3. Fetch `origin --prune` and verify that no unrelated process changed the
   checkout while the queue was being prepared.

Before switching to each PR branch:

- Re-query the PR from the canonical base repository. Skip it if it is no
  longer open, its head repository is missing, or its canonical head
  repository differs from the target base repository.
- Require the current checkout to be clean and free of an unresolved merge or
  rebase. Re-check the current branch before every switch.
- Fetch the expected head branch and verify its remote SHA. If the local branch
  does not exist, create it from the exact `origin/<head-branch>` ref. If it
  exists, switch to it only when it is not checked out in another worktree and
  fast-forward it when it is strictly behind the remote. Stop processing that
  PR on an ahead or diverged branch, missing remote ref, branch collision, or
  changed head identity. Never reset, discard, stash, force-push, or silently
  overwrite local work.
- After the switch, let `pr-fix` perform its normal exact-head checkout
  validation.

After each PR, require a clean checkout before continuing. A per-PR failure is
recorded and the next PR is attempted when the checkout is still safe to
switch. If a failure leaves dirty files, unresolved conflicts, a rebase in
progress, or an unverifiable branch state, preserve that state and stop the
batch rather than trying to repair it destructively.

## Batch queue

For an explicit list, retain the supplied PR-number order. Reject duplicate
numbers instead of attempting the same PR twice.

For `all`, query the target repository's open PRs with pagination until the
complete result is available. Include draft PRs and PRs targeting any base
branch. Snapshot at the beginning so PRs opened after the query are not added
implicitly. Sort the snapshot by ascending PR number. Keep each PR's URL,
base branch, head repository, head branch, head SHA, and draft state for
reporting and pre-switch verification.

Fork PRs are not eligible in batch mode. Record them as skipped with their
canonical head repository and continue to the next eligible PR. This does not
change the single-PR flow, which can still operate from a checkout of a fork
head repository.

## Procedure

Run the following procedure independently for every eligible queued PR. Treat
Steps 1 through 5 as a retry loop capped at **10 iterations**. Only
unresolved Copilot findings, merge conflicts, and CI failures retry the loop;
other failures stop the current PR. Approval state and review-request
timestamps are initialized separately for every PR and never carry over to a
different PR.

Before the first iteration for the current PR:

1. Retrieve `baseRefName` for the PR. URL-encode it as one path segment and
   query the active rules with:

   ```bash
   gh api --hostname <base-host> \
     "repos/<base-owner>/<base-repo>/rules/branches/<encoded-base-ref>"
   ```

   Stop this PR if the query fails. Do not infer review availability from
   local files.
2. Record whether the response contains a rule whose `type` is
   `copilot_code_review`. This value controls the full retry loop for this PR.
3. Initialize persistent approval state: an unset approval-request timestamp
   and no recorded approval. Keep both across retries for this PR only.

### Step 1: Resolve Copilot Code Review feedback

1. Use `pr-fix` in `all` mode with `--skip-copilot-review` for this PR,
   passing the same PR URL or number-and-base-repository input. It must
   operate in the current checkout and resolve conflicts, CI failures, and
   review feedback there. `pr-merge` owns the single Copilot request and wait
   for this iteration.
2. If the effective rules do not include `copilot_code_review`, record that
   review is disabled and continue to Step 2.
3. If review is enabled, retrieve the PR node ID:

   ```bash
   gh pr view <PR_NUMBER> -R <base-repository> --json id -q .id
   ```

4. Immediately before requesting the review, record the UTC timestamp. Request
   `copilot-pull-request-reviewer` with a GraphQL `requestReviews` mutation
   using bot ID `BOT_kgDOCnlnWA`.
5. Poll once per minute for up to 30 minutes for a review from
   `copilot-pull-request-reviewer` whose `submittedAt` is after the request
   timestamp. Use `gh pr view <PR_NUMBER> -R <base-repository> --json
   latestReviews`.
6. Count unresolved Copilot findings with a GraphQL query against
   `<base-host>`. Paginate `reviewThreads(first: 100, after: $cursor)` until
   `pageInfo { hasNextPage endCursor }` has no next page, and count unresolved
   threads whose first comment author is `copilot-pull-request-reviewer`.
7. If unresolved findings remain, return to the top of the retry loop.

### Step 2: Mark the PR ready for review

- Run `gh pr ready <PR_NUMBER> -R <base-repository>`.
- This is idempotent and safe to repeat when the loop retries.

### Step 3: Establish persistent approval state

1. Query `reviewDecision` and current reviews after the PR is ready.
   - If `reviewDecision` is null or empty, record that approval is not
     required and skip the label request and Step 4.
   - If it is `APPROVED`, record the valid review identity and `submittedAt`
     and skip the label request and wait.
   - Otherwise, continue with the approval request. On later iterations, keep
     a recorded approval only while GitHub still reports `APPROVED`.
2. If approval is required, no valid approval exists, and no approval request
   has been made for this PR, record the current time and run:

   ```bash
   gh pr edit <PR_NUMBER> -R <base-repository> --add-label "self approval"
   ```

   Do not remove and re-add the label to retrigger automation.
3. If GitHub reports that the required label does not exist, stop this PR. Do
   not create the label or retry the request.

### Step 4: Wait for bot approval

- Skip this step when approval is not required or a valid approval remains.
- Otherwise, poll once per minute for `reviewDecision` and current reviews.
  When GitHub reports `APPROVED`, require the corresponding new review to have
  a `submittedAt` at or after the persistent approval-request timestamp.
- If approval is still required after 3 minutes from the single label request,
  stop this PR and report that the approval automation is not configured or
  running. Do not retry with another label request.

### Step 5: Wait for CI and re-check mergeability

- Poll once per minute for up to 30 minutes:
  - Run `gh pr checks <PR_NUMBER> -R <base-repository> --required`.
  - Query `mergeable`, `mergeStateStatus`, and `headRefOid` with
    `gh pr view <PR_NUMBER> -R <base-repository>`.
- If `mergeable` is `CONFLICTING`, return to the retry loop so `pr-fix`
  resolves it.
- If any required check fails, return to the retry loop so `pr-fix` can
  attempt a repair.
- If all required checks pass or are skipped and there is no conflict, proceed
  to Step 6. If they remain pending for 30 minutes, stop this PR and report
  the timeout.

### Step 6: Squash merge the verified head

1. Retrieve the PR head repository, branch, and SHA again:

   ```bash
   gh pr view <PR_NUMBER> -R <base-repository> \
     --json headRepository,headRefName,headRefOid
   ```

   Resolve the head repository through GitHub. Stop this PR if it is missing or
   its canonical identity differs from the repository verified for this
   invocation.
2. Require the invoking checkout's expanded `origin` fetch URL to resolve to
   the verified head repository and its current branch to equal
   `<head-branch>`. In batch mode, the head repository is the target base
   repository; in single-PR mode it may be the verified fork repository.
3. Before every merge-related mutation, re-check the current branch and
   working state, run `git fetch origin --prune`, and verify all of the
   following:
   - `git status --porcelain` is empty.
   - Local `HEAD`, `origin/<head-branch>`, and the PR `headRefOid` are
     identical.
   - No other actor changed the branch or checkout while the skill waited.
4. Squash merge with the checked SHA, without `--delete-branch`:

   ```bash
   gh pr merge <PR_NUMBER> -R <base-repository> --squash \
     --match-head-commit <head-ref-oid>
   ```

5. Confirm that the PR is merged. If the merge command fails or the PR remains
   open, report failure for this PR and leave the checkout unchanged.
6. Do not delete the local branch or switch branches in this step. Delete the
   remote head branch only when it still equals the verified PR head SHA:

   ```bash
   if remote_ref="$(git ls-remote origin "refs/heads/<head-branch>")"; then
     remote_oid="${remote_ref%%[[:space:]]*}"
     if [ -n "$remote_ref" ] && [ "$remote_oid" = "<head-ref-oid>" ]; then
       git push \
         --force-with-lease="refs/heads/<head-branch>:<head-ref-oid>" \
         origin --delete <head-branch>
     fi
   else
     echo "Could not verify the remote head branch; leaving it in place" >&2
   fi
   ```

   A missing remote ref is already clean. If `ls-remote` fails, the remote ref
   changed, or deletion fails, report a cleanup warning without treating the
   already-merged PR as failed.

## Batch completion

After a queued PR finishes, classify it as `merged`, `failed`, or `skipped` and
attach its URL, step, review decisions, and cleanup warnings. When the current
checkout is clean and no operation is in progress, switch to the next eligible
head branch and repeat the per-PR procedure.

When the queue is exhausted, return to the branch saved at batch start. Verify
that the branch is still present and that the checkout is clean before and
after restoration. If restoration is unsafe or fails, report it separately and
do not report the batch as fully successful. For `all` with no open PRs, report
an explicit no-op result.

The batch result must distinguish:

- merged PRs;
- failed PRs with the step and retry state where they stopped;
- skipped PRs, including fork heads and PRs no longer open;
- remote branch cleanup warnings;
- whether Copilot Code Review or self approval was skipped for each PR;
- whether the original branch was restored.

Do not report a batch as fully successful when any requested PR failed, was
skipped, or the starting branch could not be restored.

## Retryable vs. non-retryable failures

| Condition | Behavior for the current PR |
| --- | --- |
| Effective base-branch rules cannot be retrieved | Not retryable — stop and report |
| Unresolved Copilot Code Review findings | Retryable — return to Step 1 |
| Merge conflict detected | Retryable — return to Step 1 |
| CI failure detected | Retryable — return to Step 1 |
| Missing required `self approval` label | Not retryable — stop and report |
| Required bot-approval timeout | Not retryable — stop and report |
| Enabled review-completion timeout | Not retryable — stop and report |
| CI/mergeability wait timeout | Not retryable — stop and report |
| Dirty, wrong-branch, or out-of-date current checkout | Not retryable — stop and report |
| Merge request fails or PR remains open | Not retryable — stop and report |
| Loop exceeds 10 iterations | Not retryable — stop and report |

In batch mode, a non-retryable failure is followed by the next PR only when
the checkout is clean, no merge or rebase is active, and the next branch can be
verified without discarding work. A fork head, a closed PR, or a duplicate
input is a skipped result rather than a retry. An unsafe checkout state stops
the entire batch and leaves all recoverable state in place.

Keep the approved review identity and timestamp outside the retry loop for the
current PR only. Reuse it only while GitHub continues to report
`reviewDecision: APPROVED`; this prevents a stale review from satisfying a
repository that dismisses approvals after later conflict or CI fixes.

## Constraints

- Poll waiting steps once per minute.
- Time out enabled review completion and CI/mergeability waits after 30
  minutes, and required bot approval after 3 minutes.
- Limit each PR's retry loop to 10 iterations.
- Never create the `self approval` label automatically.
- Do not force-push branch updates unless explicitly instructed. The
  lease-protected remote branch deletion in Step 6 is the sole exception.
- Only use squash merges, matching this repository's merge strategy settings.
- Never create or use a worktree, automatically change branches in
  single-PR mode, or use a destructive command to make a batch switch possible.

## Output

- For a single PR, report the merged PR URL on success, or the failure reason
  and step on failure.
- For a batch, report the per-PR result table and the overall incomplete or
  successful status, including branch restoration.
- Report when Copilot Code Review or self approval was skipped because the
  repository configuration did not require it.
- Report a remote-branch cleanup warning separately from a successful merge.
