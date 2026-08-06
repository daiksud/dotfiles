---
name: pr-fix
description: Bring an existing GitHub Pull Request into a mergeable state from its checked-out head branch. Use when asked to fix a PR, resolve merge conflicts, repair failing CI checks, address unresolved review feedback, or run all of these workflows in sequence. Accept a PR URL, or a PR number with its base repository, and an optional all, ci, feedback, or conflicts mode.
---

# pr-fix

Bring a Pull Request into a mergeable state from the invoking Git checkout.
This skill never creates a `gh-qw`, Git, or other worktree, and it never
switches the invoking checkout to another branch.

## Inputs

Accept a PR URL, or a PR number paired with its canonical base repository, and
an optional mode:

- A URL identifies both the base repository and PR number.
- For a numeric input, require an explicit host-qualified base repository, such
  as `github.com/owner/repo #42`. Do not infer the base from a fork checkout.
- Omit the mode or use `all` to fix everything in this order: conflicts, CI,
  then feedback.
- Use `ci` to fix CI failures only.
- Use `feedback` to handle review comments only.
- Use `conflicts` to resolve merge conflicts only.

## Checkout preconditions

Complete these checks before the selected mode.

1. Use the invoking Git checkout. It may be an ordinary clone, a gh-qw main
   worktree, or a linked worktree. Do not reject it solely because its `.git`
   entry is a pointer file.
2. Resolve the base repository from the supplied PR URL or explicit base
   repository through GitHub. Record its canonical URL, lowercase host,
   canonical `nameWithOwner`, and default branch. Define `<base-repository>` as
   the host-qualified `<base-host>/<base-owner>/<base-repo>`.
3. Retrieve the PR explicitly from that base identity:

   ```bash
   gh pr view <PR_NUMBER> -R <base-repository> \
     --json headRefName,headRepository,baseRefName,url
   ```

4. Stop if `headRepository` is null, which commonly means that a fork was
   deleted. Resolve the head repository through GitHub on the base host and
   record its canonical URL, lowercase host, and canonical `nameWithOwner`.
5. Require the invoking checkout's expanded `origin` fetch URL to resolve to
   that canonical head repository. Require its current branch to equal
   `headRefName`, and stop on detached `HEAD`.
6. Inspect `git status --porcelain`. It must be empty before the skill makes
   any change. Do not stash, discard, or move unrelated changes.
7. Fetch `origin --prune` and require `origin/<head-branch>` to exist:
   - If local `HEAD` equals the remote head, continue.
   - If the clean local branch is behind, run
     `git merge --ff-only origin/<head-branch>`.
   - If local `HEAD` is ahead or diverged, stop rather than overwriting or
     applying fixes to a stale branch.
8. Verify push access with
   `git push --dry-run origin <head-branch>`. For a fork PR, this checks access
   to the fork instead of assuming that the base repository is writable.
9. Never create or use `gh qw`, `git worktree`, another checkout, or an
   automatic branch switch. If the checkout does not meet these requirements,
   stop and report the canonical head repository URL and head branch so the
   user can prepare the correct checkout.

Use the invoking checkout for all Git changes. Pass `-R <base-repository>` to
every `gh pr` command so API requests continue to target the verified base
repository when the PR head is a fork.

## Working safely in the current checkout

- Before resuming after a wait and before each commit, push, or merge-related
  command, confirm that the current branch is still `<head-branch>`.
- Before the first edit, require a clean checkout. Before a commit, stage only
  the intended paths and review the full staged diff. After a commit and before
  a push, stop if unexpected unstaged or untracked content remains.
- Re-fetch and re-check the remote head before a push. Stop if another actor
  changed the branch in a way that cannot be fast-forwarded safely.
- A single checkout cannot safely host concurrent PR workflows. Use separate
  checkouts, such as linked worktrees or ordinary clones, when a user, another
  agent, or automation needs to work on another branch at the same time.

## Modes

### ci — Fix CI failures

- Retrieve CI status with `gh pr checks <PR_NUMBER> -R <base-repository>`.
- If any checks are failing, inspect their logs and identify the root cause.
- Apply fixes in the invoking checkout, run the smallest relevant local
  validation, and repeat until all CI checks pass.
- Commit and push from the invoking checkout once CI is green.
- If the CI failures cannot be resolved after 3 attempts, stop and report the
  issue.

### conflicts — Resolve merge conflicts

- Retrieve `baseRefName` during checkout preparation.
- Fetch the PR base into the invoking checkout. For a same-repository PR, use
  `origin/<base-ref>`. For a fork PR, configure or reuse an `upstream` remote
  for the base repository, then fetch `upstream/<base-ref>`.
- Before fetching a newly configured or reused `upstream`, resolve its expanded
  fetch URL through GitHub and require its canonical URL and full
  host/owner/repository identity to equal the recorded base identity. Stop on
  an unverifiable or mismatched remote instead of rewriting it.
- Merge the fetched base into the head branch and resolve every conflict while
  preserving the intent of the PR changes. Prefer a merge over a rebase so the
  result can be pushed without force-pushing.
- Identify all conflicted files. Unless the base-branch change is obviously
  correct, resolve each conflict deliberately rather than accepting one side
  wholesale.
- Commit the resolution with a clear message and push from the invoking
  checkout.

### feedback — Handle review comments

- Retrieve all unresolved review comments and replies from the base repository.
  Run every GraphQL query against `<base-host>` explicitly.
- Paginate `reviewThreads(first: 100, after: $cursor)` until
  `pageInfo { hasNextPage endCursor }` reports no next page.
- If a thread contains a user reply stating that it will not be addressed,
  such as "対応しない", do not change code for that comment. Record the reason
  in the PR body.
- Evaluate every remaining comment:
  - **Valid** — Apply the fix in the invoking checkout. For a reported error
    case, write a failing unit test first, then fix the code until it passes.
  - **Not valid / not applicable** — Do not change code. Prepare a reply that
    explains why.
- After pushing, reply to every comment from the base repository. Prefix every
  comment body with `:robot:`.
  - If fixed, explain the changes.
  - If not fixed, explain why the feedback is not applicable.
  - If the user declined it, state that it will not be addressed and that the
    reason is recorded in the PR body.
- Resolve the review threads after sending their replies.
- Determine whether Copilot Code Review is enabled for the base branch:
  1. URL-encode `baseRefName` as one path segment.
  2. Query
     `repos/<base-owner>/<base-repo>/rules/branches/<encoded-base-ref>` with
     `gh api --hostname <base-host>`.
  3. Stop if the query fails. Do not guess from local files.
  4. If no rule has `type` equal to `copilot_code_review`, report that review
     is disabled and skip the request.
- When the effective rules include `copilot_code_review`, request a review:
  - Retrieve the PR node ID with
    `gh pr view <PR_NUMBER> -R <base-repository> --json id -q .id`.
  - Use that node ID in a GraphQL `requestReviews` mutation with bot ID
    `BOT_kgDOCnlnWA` for `copilot-pull-request-reviewer`.
  - Do not use `gh pr edit --add-reviewer`; GitHub rejects bots as
    non-collaborators through that REST API.

### default / all — Fix everything

If no mode is specified, or if `all` is specified, run the modes in this
order: **conflicts -> ci -> feedback**. Resolve conflicts first so CI runs
against the mergeable branch.

## Common steps

### Perform a local review before pushing

- Before committing and pushing, perform an independent local code review. Use
  an available dedicated review skill or review subagent when the host provides
  one. Otherwise, make a separate pass over the full diff for correctness,
  regressions, security, and test coverage.
- Do not commit or push while unresolved significant issues remain.

### Update the PR title and description

- After making fixes and pushing, update the PR title and description so they
  accurately reflect the current state.
- Retrieve the current title and description first, because another person may
  have updated them.
- Use `gh pr edit <PR_NUMBER> -R <base-repository> --title` and
  `gh pr edit <PR_NUMBER> -R <base-repository> --body` to apply updates.

## Constraints

- Keep the invoking checkout on the PR head branch. Do not create a worktree
  or switch to another branch as a workaround.
- Make one commit per logical fix and use a clear message.
- Do not force-push unless explicitly instructed.
- Preserve recoverable state and stop on an unsafe checkout, missing remote
  branch, deleted fork, identity mismatch, or concurrent branch update.

## Output

- Report whether Copilot Code Review was requested or skipped because the
  effective base-branch rules do not enable it.
- Report any availability-query failure as a blocking error rather than
  treating Copilot Code Review as enabled or disabled.
