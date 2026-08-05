---
name: pr-create
description: Create a draft GitHub Pull Request from current committed or uncommitted changes in the invoking checkout while preserving source state and following repository conventions. Use only when the user explicitly asks to create, open, prepare, or draft a PR. Within that PR workflow, commit, push, associate an issue, write the description, and assign the requester as needed. Do not use for standalone branch migration, commit, push, issue, or assignment requests without PR intent.
---

# pr-create

## Overview

Create a draft Pull Request (PR) from the invoking ordinary clone. This skill
does not create or use a `gh-qwt`, Git, or other worktree. When it starts on
the default branch, it creates a feature branch in the same checkout after
confirming that the checked-out commit matches the remote default branch.
Staged, unstaged, and non-ignored untracked changes remain in that checkout
when the feature branch is created.

## Checkout rules

- Treat the ordinary clone in which the request originated as the only
  workspace for this skill. Require a real `.git` directory at its root and
  require `git config --get qwt.managed` not to return `true`. Stop when the
  caller is in a linked worktree or a gh-qwt-managed checkout; creating a
  feature branch there can move gh-qwt's primary checkout away from its pinned
  default branch.
- Run repository commands in that clone, or use `git -C <checkout>` when an
  explicit path is needed.
- Require a non-detached `HEAD`, a resolvable `origin`, and a repository
  identity resolved through GitHub before changing branches, committing, or
  pushing. Record the canonical base URL, lowercase host, canonical
  `nameWithOwner`, and default branch.
- Never create or use `gh qwt`, `git worktree`, or another checkout. Never
  reset, rebase, force-push, or rewrite the default branch to prepare a PR.
- Fetch `origin --prune` before selecting a branch. If the current branch is
  the default branch, require `HEAD` to equal `origin/<default-branch>`.
  Staged, unstaged, and non-ignored untracked changes may remain; creating a
  new branch at the same commit preserves them. If the default branch is
  ahead, behind, or diverged, stop and ask the user to resolve it rather than
  pulling, rebasing, resetting, or branching from an uncertain base.
- If the current branch is not the default branch, use it as the PR branch.
  Before changing it, query the canonical base repository for any open,
  closed, or merged PR with that head branch. Stop if one exists; use the
  existing PR or ask the user for a new branch instead of reusing a branch
  whose history may already have been merged.
- A single checkout cannot safely host concurrent PR workflows. Use separate
  clones when a user, another agent, or an automation needs to work on another
  branch at the same time.
- Before staging, committing, or pushing, re-check the current branch and
  inspect the full working state. Stop if the checkout changed branch or
  contains changes outside the intended PR scope.

## Procedure

### Step 1: Check the corresponding Task (GitHub Issue)

- First, check whether there is a GitHub Issue (Task) corresponding to this
  change.
  - Infer the related issue from the request context, the source branch name,
    commit messages, and so on.
  - If you can infer it, inspect it with `gh issue view <number> --comments`
    and verify that it matches the changes.
  - Read both the issue description and its comments to understand the intent,
    background, and discussion flow.
- If the corresponding task cannot be inferred easily, ask the user.
- If there is no corresponding task, encourage the user to create one. If one
  is created, record its number for `closes #<number>` in the PR description.

### Step 2: Inspect the checkout and changes

1. Record the checkout's absolute root, current branch, `HEAD`, staged diff,
   unstaged diff, untracked-file list, and `git status --porcelain=v1 -z`.
2. Resolve the selected `origin` URL through GitHub. Record the canonical
   repository URL, lowercase host, canonical `nameWithOwner`, and default
   branch. Define `<base-repository>` as the host-qualified
   `<host>/<owner>/<repo>` value.
3. Stop if `HEAD` is detached, the repository cannot be resolved by `gh`, or
   the branch, canonical URL, host, owner, repository, or default branch
   cannot be determined.
4. Read the full staged diff with `git diff --staged`, or the committed diff
   with `git diff origin/<default-branch>..`, as appropriate. Read every
   changed file and understand what changed and why.
5. If the changes span multiple logical units, consider splitting them into
   multiple commits.

### Step 3: Select the PR branch in the current checkout

1. Run `git fetch origin --prune`.
2. If the current branch is the default branch:
   - Require `HEAD` to equal `origin/<default-branch>`. If it does not, stop;
     do not pull, rebase, reset, or create a feature branch from it.
   - Derive a new feature branch name from the change. If it cannot be
     inferred safely, ask the user.
   - Map branch prefixes to the change type: use `feat/` for product features,
     `fix/` for product fixes, and accurate prefixes such as `docs/`,
     `chore/`, `ci/`, or `build/` for other work.
   - Require that neither a local branch nor a remote-tracking branch already
     uses the selected name. Stop instead of attaching the current changes to
     an existing branch.
   - Create and select the branch with `git switch -c <target-branch>`.
     Confirm that staged, unstaged, and non-ignored untracked changes still
     match the state recorded in Step 2.
3. Otherwise, set `<target-branch>` to the current branch. Query
   `gh pr list --state all --head <target-branch> -R <base-repository>` before
   editing. If it returns an existing PR, stop and report its URL and state.
4. Confirm that the current branch is exactly `<target-branch>` before
   continuing.

### Step 4: Create a commit in the current checkout

- Confirm which changes belong in the PR. If the checkout contains unrelated
  changes, ask the user which paths to include instead of staging them
  silently.
- Stage every intended uncommitted path explicitly. Use `git add -A` only when
  the user has confirmed that the whole working state belongs in the PR.
- Inspect the full staged diff and verify it matches the intended scope. Run
  `git diff --staged --quiet` and interpret the exit status:
  - Exit 1 means staged changes exist; commit them.
  - Exit 0 means there is nothing to commit. Continue only when the intended
    changes are already committed on `<target-branch>` relative to
    `origin/<default-branch>`; otherwise stop instead of creating an empty PR.
  - Any other exit status is an error; stop and report it.
- Use an English Conventional Commit message. Read recent commits with
  `git log --no-merges --oneline -100` and follow repository conventions.
- Before committing, confirm that the current branch remains
  `<target-branch>` and that the staged diff contains only the intended paths.

### Step 5: Push the PR branch

- Before pushing, confirm that the current branch is `<target-branch>`, inspect
  `git status --porcelain`, and stop if any unexpected unstaged or untracked
  content remains.
- Push with `git push --set-upstream origin <target-branch>`.
- Do not force-push. If the remote rejects the push because the branch changed,
  stop and report the divergence.

### Step 6: Create the PR description and open a draft PR

- If `.github/pull_request_template.md` exists, follow its structure.
- Write the PR body in English. Use GitHub Flavored Markdown features such as
  tables, alerts, Mermaid diagrams, emoji, task lists, or details blocks only
  when they make the explanation clearer.
- Include the purpose, background, and `closes #<number>` when a related issue
  was confirmed or created.
- Immediately before creating the PR, confirm that the current branch is still
  `<target-branch>`. Create the draft PR with:

  ```bash
  gh pr create --draft -R <base-repository> \
    --base <default-branch> --head <target-branch>
  ```

  This binds the PR to the verified base repository, base branch, and head
  branch instead of accepting a local `gh-merge-base` setting or a changed
  current branch.
  - Use an English Conventional Commit title:
    `<type>(<scope>): <description>`.
  - Use `feat` and `fix` only for product-impacting changes. Use an accurate
    type such as `docs`, `chore`, `ci`, or `build` otherwise.
  - Apply labels that match the change without assigning product labels to
    non-product work.

### Step 7: Assign the requesting user

- Set the requesting user as the PR assignee with
  `gh pr edit <PR_NUMBER> -R <base-repository> --add-assignee <username>`.

### Step 8: Align the Issue (Task) description with the final changes

- If there is a corresponding task and its description no longer matches the
  final PR, preserve the original plan in a comment and update the issue
  description to match the final changes.
- Do not rewrite an issue whose description already matches the final PR.

## Output

Open the created draft PR URL in the browser and report it to the user.
