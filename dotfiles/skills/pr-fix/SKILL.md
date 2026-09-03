---
name: pr-fix
description: Bring an existing GitHub Pull Request into a mergeable state from a dedicated worktree checked out from its remote head. Use when asked to fix a PR, resolve merge conflicts, repair failing CI checks, address unresolved review feedback, or run all of these workflows in sequence. Accept a PR URL, or a PR number with its base repository, an optional all, ci, feedback, or conflicts mode, and an optional flag for callers that own Copilot review requests.
---

# pr-fix

Bring a Pull Request into a mergeable state from a dedicated worktree created
for that PR. The invoking checkout supplies repository context only; it stays
on its current branch, and its files and uncommitted changes are not used for
the fix.

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
- When `pr-merge` invokes this skill, it passes `--skip-copilot-review` so
  `pr-merge` can own the single review request and wait. This flag skips only
  the post-feedback Copilot request; review comments are still handled.

## Worktree preparation

Complete these checks before the selected mode and re-run the target
validation after every retry. Use one verified dedicated worktree for the PR
for the entire invocation, preferring an existing worktree for the PR head
branch before falling back to the deterministic candidate:

`<target-worktree>` is
`<repository-parent>/.pr-worktrees/<base-host>/<base-owner>/<base-repo>/pr-<PR_NUMBER>`,
where `<repository-parent>` is the parent of the repository that owns the
invoking checkout's Git common directory. This path is keyed by the PR number,
not by the current branch, so later `pr-fix` and `pr-merge` invocations can
reuse the same worktree. Before using this candidate path, prefer an already
registered worktree checked out to `<head-branch>` when it passes the
worktree, SHA, and push-destination checks below.

1. Use the invoking checkout only to resolve repository context and launch
   worktree preparation. Confirm that
   `git rev-parse --show-toplevel` and
   `git rev-parse --path-format=absolute --git-common-dir` succeed. It may be
   an ordinary clone, a gh-qw main worktree, or a linked worktree. Do not
   reject it solely because its `.git` entry is a pointer file. Preserve any
   dirty files in this checkout, record its working state, and verify that it
   is unchanged after preparation; never stash, discard, reset, or edit them.
2. Confirm that `gh pr checkout --help` exposes `--worktree`. If it does not,
   stop rather than checking out the PR in the invoking checkout or falling
   back to another worktree implementation.
3. Resolve the base repository from the supplied PR URL or explicit base
   repository through GitHub. Record its canonical URL, lowercase host,
   canonical `nameWithOwner`, and default branch. Define `<base-repository>` as
   the host-qualified `<base-host>/<base-owner>/<base-repo>`.
   Require the invoking checkout's expanded `origin` fetch URL to resolve to
   this canonical base repository; the source checkout is the repository from
   which the PR worktree is provisioned.
4. Retrieve the PR explicitly from that base identity:

   ```bash
   gh pr view <PR_NUMBER> -R <base-repository> \
     --json headRefName,headRepository,headRefOid,baseRefName,url
   ```

5. Stop if `headRepository` is null, which commonly means that a fork was
   deleted. Resolve the head repository through GitHub on the base host and
   record its canonical URL, lowercase host, canonical `nameWithOwner`, and
   `<head-branch>`.
6. Resolve the deterministic candidate `<target-worktree>` from the Git common
   directory, but do not create it yet:

   ```bash
   git_common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
   repository_root="$(dirname "$git_common_dir")"
   target_worktree="$(dirname "$repository_root")/.pr-worktrees/<base-host>/<base-owner>/<base-repo>/pr-<PR_NUMBER>"
   ```

   Use the same absolute candidate path on every retry. Do not place the
   target inside the invoking checkout or replace an existing path that is not
   a registered Git worktree. Step 7 may replace this candidate with an
   already registered worktree for `<head-branch>`.
7. Inspect `git worktree list --porcelain`:
   - First look for a registered worktree whose branch is exactly
     `refs/heads/<head-branch>`. If one exists outside the invoking checkout,
     use its absolute path as `<target-worktree>` instead of creating the
     deterministic candidate. Require that it belongs to the same Git common
     directory, is a directory, and has no uncommitted changes. Do not switch,
     move, or force this worktree; verify its PR head SHA and push destination
     in Step 9 before editing.
   - If more than one registered worktree matches `<head-branch>`, stop and
     report the ambiguous paths rather than choosing one.
   - If the matching branch worktree is the invoking checkout, stop and report
     that the source checkout cannot be used for PR changes.
   - If no matching branch worktree exists, create only the deterministic
     candidate's parent directory with
     `mkdir -p "$(dirname "$target_worktree")"`. If the candidate is
     registered, require that it belongs to the same Git common directory, is a
     directory, and has no uncommitted changes. If the candidate path exists
     but is not registered, stop and report the collision.
8. Create or refresh the target worktree from the PR remote with the native
   GitHub CLI command:

   ```bash
   gh pr checkout <PR_NUMBER> -R <base-repository> \
     --worktree <target-worktree>
   ```

   Run this command only when Step 7 selected the deterministic candidate.
   When an existing `<head-branch>` worktree was selected, use it directly and
   do not invoke `gh pr checkout` against a branch that is already checked out.
   Do not pass `--force`. For an existing deterministic candidate, the command
   fetches the PR head from its remote repository (or the base repository's PR
   ref when the head is a fork) and reuses it. A fast-forward-only update is
   allowed; an ahead or diverged local branch is a hard stop.
9. Verify the result before editing:
   - `<target-worktree>` is a registered worktree from the same Git common
     directory, and its `HEAD` equals the latest `<head-ref-oid>` returned by
     GitHub.
   - Re-query the PR immediately before the first edit and require the target
     `HEAD` to equal the newly returned `headRefOid`; if it changed during
     preparation, refresh and validate again rather than editing a stale
     head.
   - Its working tree is clean. Record the local branch as `<local-branch>`;
     GitHub CLI may choose a disambiguated local name for a fork or a default
     branch collision.
   - Resolve `<head-remote>` from the target branch's push configuration. If
     no configured push destination exists, use the canonical head repository
     URL directly. In either case, require the expanded push URL to equal the
     canonical head repository. Push explicitly to `<head-branch>` so a
     disambiguated local branch cannot update a different remote branch.
   - Verify push access without changing the target:

     ```bash
     git -C <target-worktree> push --dry-run <head-remote> \
       HEAD:<head-branch>
     ```

   Stop if any identity, SHA, worktree, cleanliness, or push-access check
   fails. Do not continue with a stale or unpushable PR head.

Use `<target-worktree>` for every Git command that inspects, modifies, tests,
commits, or pushes the PR. Pass `-R <base-repository>` to every `gh pr`
command so API requests continue to target the verified base repository when
the PR head is a fork.

## Working safely in the target worktree

- Before resuming after a wait and before each commit, push, or merge-related
  command, confirm that `<target-worktree>` is still the registered worktree,
  its local branch is still `<local-branch>`, and its `HEAD` still belongs to
  this PR.
- Before the first edit, require a clean target worktree. Before a commit,
  stage only the intended paths and review the full staged diff. After a
  commit and before a push, stop if unexpected unstaged or untracked content
  remains.
- Before each push, record the target `HEAD` as `<pre-push-head>`, re-query the
  PR, and fetch or query `<head-remote>`. Require the SHA for
  `refs/heads/<head-branch>` and the latest PR `headRefOid` to equal
  `<pre-push-head>`, and require the local post-commit `HEAD` to descend from
  it. Push with the explicit `HEAD:<head-branch>` refspec. If another actor
  changed the PR, stop instead of rebasing, resetting, or force-pushing.
- Leave the invoking checkout exactly as it was found. A dirty invoking
  checkout is not permission to copy, stage, or clean those changes into the
  PR worktree.

## Modes

### ci — Fix CI failures

- Retrieve CI status with `gh pr checks <PR_NUMBER> -R <base-repository>`.
- If any checks are failing, inspect their logs and identify the root cause.
- Apply fixes in `<target-worktree>`, run the smallest relevant local
  validation, and repeat until all CI checks pass.
- Commit and push from `<target-worktree>` once CI is green, using
  `git push <head-remote> HEAD:<head-branch>`.
- If the CI failures cannot be resolved after 3 attempts, stop and report the
  issue.

### conflicts — Resolve merge conflicts

- Retrieve `baseRefName` during checkout preparation.
- Fetch the PR base into `<target-worktree>`. For a same-repository PR, use
  the verified base remote's `<base-ref>`. For a fork PR, configure or reuse
  an `upstream` remote for the base repository, then fetch
  `upstream/<base-ref>`.
- Before fetching a newly configured or reused `upstream`, resolve its expanded
  fetch URL through GitHub and require its canonical URL and full
  host/owner/repository identity to equal the recorded base identity. Stop on
  an unverifiable or mismatched remote instead of rewriting it.
- Merge the fetched base into the local PR branch in `<target-worktree>` and
  resolve every conflict while preserving the intent of the PR changes. Prefer
  a merge over a rebase so the result can be pushed without force-pushing.
- Identify all conflicted files. Unless the base-branch change is obviously
  correct, resolve each conflict deliberately rather than accepting one side
  wholesale.
- Commit the resolution with a clear message and push from `<target-worktree>`
  to `<head-remote> HEAD:<head-branch>`.

### feedback — Handle review comments

- Retrieve all unresolved review comments and replies from the base repository.
  Run every GraphQL query against `<base-host>` explicitly.
- Paginate `reviewThreads(first: 100, after: $cursor)` until
  `pageInfo { hasNextPage endCursor }` reports no next page.
- Before replying, list the acting user's reviews with GraphQL
  `reviews(first: 100) { nodes { id state } }` and submit or discard any
  leftover `PENDING` review from an earlier interrupted run. A stale pending
  review silently absorbs new reply comments instead of posting them.
- If a thread contains a user reply stating that it will not be addressed,
  such as "対応しない", do not change code for that comment. Record the reason
  in the PR body.
- Evaluate every remaining comment:
  - **Valid** — Apply the fix in `<target-worktree>`. For a reported error
    case, write a failing unit test first, then fix the code until it passes.
  - **Not valid / not applicable** — Do not change code. Prepare a reply that
    explains why.
- Before posting replies, consult the local GitHub comment policy at
  `$XDG_CONFIG_HOME/dotfiles/agent.toml`, or
  `~/.config/dotfiles/agent.toml` when `XDG_CONFIG_HOME` is unset. Look up the
  base repository organization under `[github.comment_prefixes]`. If it has a
  configured prefix, prepend that value and a single space to every comment
  body. If no prefix is configured, do not add an organization-specific
  prefix. If the file exists but cannot be read or parsed, stop before posting
  and report the configuration error.
- After pushing, reply to every comment from the base repository.
  - If fixed, explain the changes.
  - If not fixed, explain why the feedback is not applicable.
  - If the user declined it, state that it will not be addressed and that the
    reason is recorded in the PR body.
  - A GraphQL `addPullRequestReviewComment` reply attaches to a review that
    stays in the `PENDING` state and stays invisible to the PR author until
    submitted. After adding every reply comment for this pass, submit that
    review with a `submitPullRequestReview` mutation using `event: COMMENT`.
  - Re-query the review's `state` after submitting and confirm it is no
    longer `PENDING` before moving on. Do not leave any reply unsubmitted.
- Resolve the review threads only after their replies are confirmed submitted.
- If `--skip-copilot-review` was supplied by `pr-merge`, report that the caller
  owns the Copilot request and stop the feedback mode here. Do not query the
  rules or request another review.
- Determine whether Copilot Code Review is enabled for the base branch:
  1. URL-encode `baseRefName` as one path segment.
  2. Query
     `repos/<base-owner>/<base-repo>/rules/branches/<encoded-base-ref>` with
     `gh api --hostname <base-host>`.
  3. If Copilot Code Review or the rules endpoint is unavailable, including
     plan, permission, or endpoint availability errors, report that review is
     unavailable and skip the request. Do not let this optional review block
     the feedback workflow.
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

- Always use one verified dedicated PR worktree before editing. Prefer an
  existing registered worktree for `<head-branch>`; otherwise create or reuse
  the deterministic PR worktree with `gh pr checkout --worktree`. Keep the
  invoking checkout on its original branch and never use it as the PR
  workspace.
- Keep the target worktree after the skill completes so a later `pr-fix` or
  `pr-merge` invocation can reuse it.
- Never fall back to `git checkout`, `git switch`, a normal-clone branch
  checkout, or a different unverified worktree when preparation fails.
- Make one commit per logical fix and use a clear message.
- Do not force-push unless explicitly instructed.
- Preserve recoverable state and stop on an unsafe checkout, missing remote
  branch, deleted fork, identity mismatch, worktree collision, or concurrent
  PR update.

## Output

- Report the absolute `<target-worktree>` used for the PR.
- Report whether Copilot Code Review was requested, skipped because it is
  disabled, or skipped because it is unavailable.
- Report an unavailable optional review without treating it as a blocking
  error.
