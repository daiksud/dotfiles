---
description: Use when fixing a pull request by addressing CI failures, review feedback, or merge conflicts, including when /pr fix, /pr fix ci, /pr fix feedback, or /pr fix conflicts is invoked.
name: fix-pr
---
# fix-pr

A skill that drives a Pull Request toward merge-readiness.

## Usage

Invoke with a PR number and an optional mode:

```
/pr fix #42              # Fix everything (ci → conflicts → feedback)
/pr fix ci #42           # Fix CI failures only
/pr fix feedback #42     # Address review comments only
/pr fix conflicts #42    # Resolve merge conflicts only
```

## Modes

### ci — Fix CI Failures

- Fetch the CI status of the specified PR.
- If any checks have failed, inspect the logs to identify the root cause.
- Apply fixes iteratively until all CI checks pass.
- Commit and push after CI is green.
- If a CI failure cannot be resolved after 3 attempts, stop and report the issue.

### conflicts — Resolve Merge Conflicts

- Fetch the PR's base branch and rebase or merge to surface conflicts.
- Identify all files with merge conflicts.
- Resolve each conflict, preserving the intent of the PR's changes unless the base branch change is clearly correct.
- Commit the resolved files with a clear message.
- Push the resolved branch.

### feedback — Address Review Comments

- Retrieve all unresolved review comments on the PR.
- For each comment, evaluate whether the feedback is valid:
  - **Valid** — Apply the suggested fix or improvement.
  - **Invalid / not applicable** — Do not modify the code. Prepare a reply explaining why.
- After pushing, reply to each comment explaining what action was taken:
  - If fixed: describe the change made.
  - If not fixed: explain why the comment was deemed not applicable.
- After sending the reply, resolve the review comment thread.

### (default) — Fix Everything

When no mode is specified, run all three modes in order: **ci → conflicts → feedback**.

## Common Steps (all modes)

### Local Review Before Push

- Before committing and pushing any changes, run a local code review using a sub-agent (`code-review` agent type).
- Only commit and push once the local review passes with no critical issues.

### Update PR Description

- After making any fixes and pushing, always update the PR description to accurately reflect the current state of the changes.
- Use `gh pr edit <PR_NUMBER> --body` to update.

## Constraints

- Always work on the PR's branch (checkout the branch before making changes).
- Each logical fix should be a single commit with a clear message.
- Never force-push unless explicitly instructed.
