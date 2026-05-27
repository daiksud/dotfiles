---
description: A skill that drives a Pull Request toward merge-readiness by fixing CI failures and addressing review comments
name: fix-pr
---
# fix-pr

A skill that drives a Pull Request toward merge-readiness by fixing CI failures and addressing review comments.

## Usage

Invoke with a PR number:

```
fix PR #42
```

## Behavior

### 1. Fix CI Failures

- Fetch the CI status of the specified PR.
- If any checks have failed, inspect the logs to identify the root cause.
- Apply fixes iteratively until all CI checks pass.
- Commit and push after CI is green.

### 2. Address Review Comments

- Retrieve all unresolved review comments on the PR.
- For each comment, evaluate whether the feedback is valid:
  - **Valid** — Apply the suggested fix or improvement.
  - **Invalid / not applicable** — Do not modify the code. Prepare a reply explaining why.

### 3. Local Review Before Push

- Before committing and pushing any changes, run a local code review using a sub-agent (`code-review` agent type).
- Only commit and push once the local review passes with no critical issues.

### 4. Reply to Review Comments

- After pushing, reply to each review comment explaining what action was taken:
  - If fixed: describe the change made.
  - If not fixed: explain why the comment was deemed not applicable.

## Constraints

- Always work on the PR's branch (checkout the branch before making changes).
- Each logical fix should be a single commit with a clear message.
- Never force-push unless explicitly instructed.
- If a CI failure cannot be resolved after 3 attempts, stop and report the issue.
