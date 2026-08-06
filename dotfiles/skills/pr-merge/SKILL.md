---
name: pr-merge
description: Take one GitHub Pull Request through final review, conditional approval, required CI, and squash merge from its checked-out head branch. Use when asked to merge a PR once ready, monitor it through merge, loop through enabled Copilot Code Review feedback with the pr-fix skill, apply self approval only when required, or wait for required checks. Require a PR URL or a PR number with its base repository.
---

# pr-merge

## Overview

Take one Pull Request from "ready for final review" to "merged". For the
selected PR, use `pr-fix` from the invoking checkout, request a Copilot Code
Review when the base branch requires it, wait for approval and CI, then squash
merge the verified head SHA.

This skill never creates a `gh-qw`, Git, or other worktree and never switches
the invoking checkout to another branch. It leaves the merged local branch
checked out. It can delete the matching remote head branch with a
lease-protected ref deletion, because that operation does not require changing
the local checkout.

## Inputs

- Require exactly one PR URL, or a PR number paired with its canonical
  host-qualified base repository. Do not infer the base from a fork checkout.
- Invoke this skill from a clean checkout of that PR's head repository and head
  branch. For a fork PR, the checkout must point to the fork, not the base
  repository.

## Checkout rules

- `pr-fix` owns checkout validation. Its requirements apply before every retry:
  the invoking checkout's `origin` must resolve to the PR head repository, its
  current branch must equal the PR head branch, and it must be clean before
  changes begin.
- Resolve the base repository through GitHub for every PR. Record its canonical
  URL, lowercase host, canonical `nameWithOwner`, and default branch. Define
  `<base-repository>` as the host-qualified
  `<base-host>/<base-owner>/<base-repo>` and pass it to every `gh pr` command.
- Never create or use `gh qw`, `git worktree`, another checkout, or an
  automatic branch switch. If the current checkout is not the PR head, stop
  and report the canonical head repository URL and branch.
- Before each mutating command after a wait, re-check the current branch,
  working state, remote head, and expected PR head SHA. Stop rather than
  merging, committing, or pushing if another actor changed the checkout.
- A single checkout cannot safely process several PR branches. Run one PR per
  invocation and use separate checkouts, such as linked worktrees or ordinary
  clones, for parallel PR work.

## Procedure

Treat Steps 1 through 5 as a retry loop capped at **10 iterations**. Only
unresolved Copilot findings, merge conflicts, and CI failures retry the loop;
other failures stop and report.

Before the first iteration:

1. Retrieve `baseRefName` for the PR. URL-encode it as one path segment and
   query the active rules with:

   ```bash
   gh api --hostname <base-host> \
     "repos/<base-owner>/<base-repo>/rules/branches/<encoded-base-ref>"
   ```

   Stop if the query fails. Do not infer review availability from local files.
2. Record whether the response contains a rule whose `type` is
   `copilot_code_review`. This value controls the full retry loop.
3. Initialize persistent approval state: an unset approval-request timestamp
   and no recorded approval. Keep both across retries.

### Step 1: Resolve Copilot Code Review feedback

1. Use `pr-fix` in `all` mode for this PR, passing the same PR URL or
   number-and-base-repository input. It must operate in the invoking
   checkout and resolve conflicts, CI failures, and review feedback there.
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
   - If `reviewDecision` is null or empty, record that approval is not required
     and skip the label request and Step 4.
   - If it is `APPROVED`, record the valid review identity and `submittedAt`
     and skip the label request and wait.
   - Otherwise, continue with the approval request. On later iterations, keep
     a recorded approval only while GitHub still reports `APPROVED`.
2. If approval is required, no valid approval exists, and no approval request
   has been made, record the current time and run:

   ```bash
   gh pr edit <PR_NUMBER> -R <base-repository> --add-label "self approval"
   ```

   Do not remove and re-add the label to retrigger automation.
3. If GitHub reports that the required label does not exist, stop. Do not
   create the label or retry the request.

### Step 4: Wait for bot approval

- Skip this step when approval is not required or a valid approval remains.
- Otherwise, poll once per minute for `reviewDecision` and current reviews.
  When GitHub reports `APPROVED`, require the corresponding new review to have
  a `submittedAt` at or after the persistent approval-request timestamp.
- If approval is still required after 3 minutes from the single label request,
  stop and report that the approval automation is not configured or running.
  Do not retry with another label request.

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
  to Step 6. If they remain pending for 30 minutes, stop and report the
  timeout.

### Step 6: Squash merge the verified head

1. Retrieve the PR head repository, branch, and SHA again:

   ```bash
   gh pr view <PR_NUMBER> -R <base-repository> \
     --json headRepository,headRefName,headRefOid
   ```

   Resolve the head repository through GitHub. Stop if it is missing or its
   canonical identity differs from the one `pr-fix` verified.
2. Require the invoking checkout's expanded `origin` fetch URL to resolve to
   the verified head repository and its current branch to equal
   `<head-branch>`.
3. Run `git fetch origin --prune`, then verify all of the following:
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
   open, report failure and leave the checkout unchanged.
6. Do not delete the checked-out local branch or switch to another branch.
   Delete the remote head branch only when it still equals the verified PR
   head SHA:

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

## Retryable vs. non-retryable failures

| Condition | Behavior |
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

Keep the approved review identity and timestamp outside the retry loop. Reuse
it only while GitHub continues to report `reviewDecision: APPROVED`; this
prevents a stale review from satisfying a repository that dismisses approvals
after later conflict or CI fixes.

## Constraints

- Poll waiting steps once per minute.
- Time out enabled review completion and CI/mergeability waits after 30
  minutes, and required bot approval after 3 minutes.
- Limit the retry loop to 10 iterations.
- Never create the `self approval` label automatically.
- Do not force-push branch updates unless explicitly instructed. The
  lease-protected remote branch deletion in Step 6 is the sole exception.
- Only use squash merges, matching this repository's merge strategy settings.

## Output

- Report the merged PR URL on success, or the failure reason and step on
  failure.
- Report when Copilot Code Review or self approval was skipped because the
  repository configuration did not require it.
- Report a remote-branch cleanup warning separately from a successful merge.
