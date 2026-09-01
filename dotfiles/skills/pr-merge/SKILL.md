---
name: pr-merge
description: Take one or more GitHub Pull Requests through final review, conditional approval, required CI, and squash merge from dedicated worktrees checked out from their remote heads. Use when asked to merge one PR, an ordered list of PRs, or all open PRs in the current repository. Accept a PR URL, one or more PR numbers with an optional host-qualified base repository, or all.
---

# pr-merge

## Overview

Take Pull Requests from "ready for final review" to "merged". For each
selected PR, use `pr-fix`, request a Copilot Code Review when the base branch
requires it, wait for approval and CI, then squash merge the verified head
SHA. Each PR is prepared in the deterministic worktree keyed by its PR number;
the invoking checkout is used only for repository context and remains on its
original branch.

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

## Worktree rules

### Single PR

`pr-fix` owns worktree preparation. Its requirements apply before every retry:
the invoking checkout must resolve to the verified base repository, and
`pr-fix` must create or reuse the deterministic
`<target-worktree>` for this PR with `gh pr checkout --worktree`. The source
checkout may contain unrelated changes, but it must not be changed.

Resolve the base repository through GitHub for every PR. Record its canonical
URL, lowercase host, canonical `nameWithOwner`, and default branch. Define
`<base-repository>` as the host-qualified
`<base-host>/<base-owner>/<base-repo>` and pass it to every `gh pr` command.

The target worktree path is
`<repository-parent>/.pr-worktrees/<base-host>/<base-owner>/<base-repo>/pr-<PR_NUMBER>`,
using the parent of the repository that owns the invoking checkout's Git
common directory. Never substitute the invoking checkout, a different PR's
worktree, or an unverified path.

### Batch

Batch mode is enabled when the input contains multiple PR numbers or `all`.
Before resolving the queue:

1. Require a non-bare Git checkout with a resolvable `origin`, no unresolved
   merge or rebase, and a successful `gh pr checkout --help` query exposing
   `--worktree`. The source working tree may be dirty; record it and never
   stash, discard, reset, or edit it.
2. Resolve the target base repository and require the invoking checkout's
   expanded `origin` fetch URL to equal that canonical base repository. This
   gives every PR worktree a verified base remote while allowing its head to
   be a fork.
3. Fetch the verified base remote with `--prune` and verify that no unrelated
   process changed the source checkout while the queue was being prepared.

Before preparing each PR worktree:

- Re-query the PR from the canonical base repository. Skip it if it is no
  longer open or its head repository is missing. Do not silently substitute a
  different head repository or branch.
- Let `pr-fix` create or refresh the PR-number worktree from the remote with
  `gh pr checkout <PR_NUMBER> -R <base-repository> --worktree <target-worktree>`.
  Do not pass `--force`, switch the source checkout, or reuse a worktree
  belonging to another PR.
- If the target path collides, is dirty, is ahead or diverged from the remote,
  or cannot verify push access to the canonical head repository, record the
  failure and leave it unchanged. A fork is not skipped merely because it is a
  fork; it is eligible when its head remote and push access pass validation.

Before starting the next PR, verify that its target path can be prepared and
that the source checkout is still safe. A per-PR failure, including a dirty or
conflicted target, is recorded and left in place while the next independent
worktree is attempted. If the source checkout, Git common directory, or next
target path is unsafe to continue, preserve all recoverable state and stop the
batch rather than trying to repair it destructively.

## Batch queue

For an explicit list, retain the supplied PR-number order. Reject duplicate
numbers instead of attempting the same PR twice.

For `all`, query the target repository's open PRs with pagination until the
complete result is available. Include draft PRs and PRs targeting any base
branch. Snapshot at the beginning so PRs opened after the query are not added
implicitly. Sort the snapshot by ascending PR number. Keep each PR's URL,
base branch, head repository, head branch, head SHA, and draft state for
reporting and pre-preparation verification. Fork PRs use the same isolated
worktree flow; a missing fork or unavailable push access is reported as a
per-PR skip or failure without changing the source checkout.

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

   If the rules query reports that Copilot Code Review or the rules endpoint is
   unavailable, including plan, permission, or endpoint availability errors,
   record review as unavailable and continue this PR without requesting it.
   Do not infer review availability from local files.
2. If the query succeeds, record whether the response contains a rule whose
   `type` is `copilot_code_review`. This value controls the full retry loop for
   this PR.
3. Initialize persistent approval state: an unset approval-request timestamp
   and no recorded approval. Keep both across retries for this PR only.

### Step 1: Resolve Copilot Code Review feedback

1. Use `pr-fix` in `all` mode with `--skip-copilot-review` for this PR,
   passing the same PR URL or number-and-base-repository input. It must create
   or reuse the PR-number worktree with `gh pr checkout --worktree` and resolve
   conflicts, CI failures, and review feedback there. `pr-merge` owns the
   single Copilot request and wait for this iteration.
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
   - Otherwise, query the computed merge state. If GitHub reports that the PR
     is mergeable without an approval blocker, record that `self approval` is
     unnecessary and skip the label request and Step 4.
   - Otherwise, continue with the approval request. On later iterations, keep
     a recorded approval only while GitHub still reports `APPROVED`.
2. If approval is required, no valid approval exists, and no approval request
   has been made for this PR, record the current time and run the existing
   workflow:

   ```bash
   gh pr edit <PR_NUMBER> -R <base-repository> --add-label "self approval"
   ```

   Do not remove and re-add the label to retrigger automation.
3. If GitHub reports that the label is missing or unavailable, re-query
   `reviewDecision`, `mergeable`, and `mergeStateStatus`. Continue without the
   label only when GitHub reports that the PR is mergeable without an approval
   blocker. Otherwise, stop this PR. Do not create the label or retry the
   request.

### Step 4: Wait for bot approval

- Skip this step when approval is not required, a valid approval remains, or
  the computed merge state says the PR can merge without approval.
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
2. Resolve the same `<target-worktree>` path used by `pr-fix`. Verify that it
   is registered with the invoking repository's Git common directory, its
   local branch still belongs to this PR, and its working tree is clean.
3. Resolve `<head-remote>` from the target branch's push configuration. If no
   configured push destination exists, use the verified canonical head
   repository URL directly. In either case, require its canonical push URL to
   equal the verified head repository. Before every merge-related mutation,
   re-check the target worktree, fetch the head remote with `--prune`, and
   query `refs/heads/<head-branch>` when the destination is a URL, and verify
   all of the following:
   - `git -C <target-worktree> status --porcelain` is empty.
   - The target `HEAD`, the SHA for `<head-remote>`'s
     `refs/heads/<head-branch>`, and the PR `headRefOid` are identical.
   - No other actor changed the PR, target worktree, or remote head while the
     skill waited.
4. Squash merge with the checked SHA, without `--delete-branch`:

   ```bash
   gh pr merge <PR_NUMBER> -R <base-repository> --squash \
     --match-head-commit <head-ref-oid>
   ```

5. Confirm that the PR is merged. If the merge command fails or the PR remains
   open, report failure for this PR and leave the target worktree and source
   checkout unchanged.
6. Keep the clean PR worktree and its local branch for later reuse. Delete the
   remote head branch only when it still equals the verified PR head SHA:

   ```bash
   if remote_ref="$(git -C <target-worktree> ls-remote <head-remote> \
     "refs/heads/<head-branch>")"; then
     remote_oid="${remote_ref%%[[:space:]]*}"
     if [ -n "$remote_ref" ] && [ "$remote_oid" = "<head-ref-oid>" ]; then
       git -C <target-worktree> push \
         --force-with-lease="refs/heads/<head-branch>:<head-ref-oid>" \
         <head-remote> --delete <head-branch>
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
attach its URL, target worktree, step, review decisions, and cleanup warnings.
Then create or reuse the next PR's independent worktree and repeat the per-PR
procedure. Never switch the source checkout or a different PR's worktree.

When the queue is exhausted, verify that the source checkout is still on its
original branch and that its recorded working state was not changed by the
skill. There is no branch restoration step because the source checkout is
never switched. For `all` with no open PRs, report an explicit no-op result.

The batch result must distinguish:

- merged PRs;
- failed PRs with the step and retry state where they stopped;
- skipped PRs, including PRs whose head repository was deleted or that were no
  longer open;
- remote branch cleanup warnings;
- the absolute worktree used for each PR;
- whether Copilot Code Review or self approval was skipped for each PR,
  including whether Copilot was unavailable or the PR was mergeable without
  the label;
- whether the source checkout remained unchanged.

Do not report a batch as fully successful when any requested PR failed or was
skipped, or when the source checkout changed unexpectedly.

## Retryable vs. non-retryable failures

| Condition | Behavior for the current PR |
| --- | --- |
| Copilot Code Review or its rules endpoint is unavailable | Skip the optional review and continue |
| Unresolved Copilot Code Review findings | Retryable — return to Step 1 |
| Merge conflict detected | Retryable — return to Step 1 |
| CI failure detected | Retryable — return to Step 1 |
| Missing `self approval` label while approval blocks the PR | Not retryable — stop and report |
| Required bot-approval timeout | Not retryable — stop and report |
| Enabled review-completion timeout | Not retryable — stop and report |
| CI/mergeability wait timeout | Not retryable — stop and report |
| Dirty, wrong-branch, or out-of-date target worktree | Not retryable — stop and report |
| Merge request fails or PR remains open | Not retryable — stop and report |
| Loop exceeds 10 iterations | Not retryable — stop and report |

In batch mode, a non-retryable failure is followed by the next PR only when
the source checkout and every target worktree remain safe, no merge or rebase is
active, and the next worktree can be verified without discarding work. A
closed PR, deleted head repository, or duplicate input is a skipped result
rather than a retry. An unsafe checkout or worktree state stops the entire
batch and leaves all recoverable state in place.

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
- Do not add the `self approval` label when GitHub reports that the PR can
  merge without an approval blocker.
- Do not force-push branch updates unless explicitly instructed. The
  lease-protected remote branch deletion in Step 6 is the sole exception.
- Only use squash merges, matching this repository's merge strategy settings.
- Always create or reuse one deterministic PR worktree with
  `gh pr checkout --worktree` before `pr-fix` starts changing files. Never use
  the source checkout for PR changes or automatically switch branches there.
- Never fall back to a normal-clone checkout, reuse another PR's worktree, or
  use a destructive command to make worktree preparation possible.

## Output

- For a single PR, report the merged PR URL on success, or the failure reason
  and step on failure.
- For a batch, report the per-PR result table and the overall incomplete or
  successful status, including each worktree path and source-checkout status.
- Report when Copilot Code Review was skipped because it is disabled or
  unavailable, and when self approval was skipped because it was unnecessary
  or the PR was mergeable without the label.
- Report a remote-branch cleanup warning separately from a successful merge.
