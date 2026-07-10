---
name: pr-create
description: A skill used when creating a Pull Request. This also applies when `/pr create` is invoked. It creates a draft PR according to the repository conventions.
---

# pr-create

## Overview

This skill creates a draft Pull Request (PR) from the current changes.
It uses `gh-qwt` to give the PR branch its own worktree rather than switching
branches in a shared checkout.

## When to use

- When asked to "create a PR"
- When `/pr-create` or `/pr create` is invoked in GitHub Copilot CLI

## Workspace rules

- `gh qwt` is the only workspace mechanism for this skill. If it is
  unavailable, the repository is not hosted on GitHub, or qwt cannot create
  the requested path, stop and report the problem.
- Never run `git switch`, `git checkout`, `git worktree`, or a normal-clone
  branch-switching fallback. Create and select branches only through
  `gh qwt get` and `gh qwt add`.
- Resolve the target with `gh qwt path <owner>/<repo>/<branch>` and run every
  repository command against that absolute path, for example
  `git -C "$worktree" status`. Do not rely on the invoking directory after the
  target worktree has been selected.
- Never use `git reset --hard`, force-push, or `gh qwt remove --force` to move
  changes. An unsafe migration must stop with the source worktree or an
  identifiable stash intact.

## Procedure

### Step 1: Check the corresponding Task (GitHub Issue)

- First, check whether there is a GitHub Issue (Task) corresponding to this
  change.
  - Infer the related issue from the context at skill invocation time, the
    source branch name, commit messages, and so on.
  - If you can infer it, inspect it with `gh issue view <number> --comments`
    and verify that it matches the changes.
  - Read not only the issue description but also the comments to understand
    the intent, background, and flow of discussion.
- If the corresponding task cannot be inferred easily, ask the user.
  - Example: "Is there a Task (Issue) associated with this change? If so,
    please tell me the number."
- If there is no corresponding task, encourage the user to create one.
  - If creating a task, suggest `gh issue create`.
  - After creating the task, note its number and use it in a later step
    (`closes #XXX` in the PR description).

### Step 2: Understand the source changes deeply

- Treat the checkout in which the skill was invoked as the **source
  worktree**. Record its absolute root, current branch, `HEAD`, staged diff,
  unstaged diff, untracked-file list, and `git status --porcelain=v1 -z`
  before changing anything.
- Read the full staged diff with `git -C <source> diff --staged`, or the
  committed diff with `git -C <source> diff origin/<default-branch>..`, as
  appropriate. Resolve the default branch in Step 3 before using the latter
  command. Always focus on what changes will be applied relative to the remote
  default branch.
- Read the diff for each file and understand **what** changed and **why**.
  For new files, read the entire file to understand its purpose and role.
- Consider the context and reasons provided when the skill was invoked. When
  inferring the change details or background, also refer to the corresponding
  issue description and comments.
- If the changes span multiple logical units, consider splitting them into
  multiple commits.

### Step 3: Prepare the qwt feature worktree

#### Resolve the repository and source state

1. Confirm that `gh qwt --help` succeeds.
2. Resolve the canonical GitHub repository and default branch from the source
   worktree:
   - `gh repo view --json nameWithOwner,defaultBranchRef`
   - `git -C <source> branch --show-current`
   - `git -C <source> rev-parse HEAD`
3. Stop if `HEAD` is detached, the repository cannot be resolved by `gh`, or
   the source branch cannot be determined.
4. Determine whether a qwt repository already exists by checking that
   `$(gh qwt path <owner>/<repo>)/.bare` is a directory. A normal clone,
   including an ordinary linked worktree, is not a qwt repository.
5. Before using `gh qwt add` in an existing qwt repository, refresh its
   branch metadata with:

   ```bash
   git -C "$(gh qwt path <owner>/<repo>)" fetch origin --prune
   ```

   This is the narrow exception to target-worktree command scoping: `gh qwt
   add` consults cached branch refs and does not fetch them itself.

#### Choose the target branch and create its worktree

- If the source is already the qwt worktree for a non-default feature branch,
  use that worktree as the target. Verify that its checked-out branch matches
  the branch name; do not create another worktree.
- Otherwise, derive a new feature branch name from the change. If the name
  cannot be inferred safely, ask the user.
  - The branch name should reflect the changes (for example,
    `feat/add-pr-create-skill` or `fix/pin-terraform-provider-github-660`).
  - Map branch prefixes to Conventional Commit types: `feat` -> `feat/*`,
    `fix` -> `fix/*`, `docs` -> `docs/*`.
  - Do **not** use `feat/*` or `fix/*` branch names for changes that do not
    affect the actual product deliverable, such as build tooling, CI/CD
    configuration, or repository infrastructure. Use an accurate prefix such
    as `docs/*`, `chore/*`, `ci/*`, or `build/*`.
- Before migrating a default-branch source, fetch its default branch and
  compare `HEAD` with `origin/<default-branch>`.
  - If the default branch has local commits or the base does not match, stop.
    Do not reset, rebase, or push the default branch automatically.
  - The target branch must be new. If a local or remote branch with the chosen
    target name already exists in the qwt repository, stop rather than
    applying the default-branch changes to it.
- For a non-default source in an ordinary clone, publish its committed branch
  with `git -C <source> push --set-upstream origin <source-branch>` before
  creating its qwt counterpart. This transfers committed work without a
  checkout. Stop if the push is rejected.
- If the qwt repository does not yet exist:
  - For an existing remote target branch from a non-default source, run
    `gh qwt get <owner>/<repo> --branch <target-branch>`.
  - For a new target branch, run `gh qwt get <owner>/<repo>` first, then run
    `gh qwt add --repo <owner>/<repo> <target-branch> --from origin/<default-branch>`.
- If the qwt repository exists but the target worktree does not, run
  `gh qwt add --repo <owner>/<repo> <target-branch>`. Add
  `--from origin/<default-branch>` only when creating a new branch.
- If a separate target worktree already exists while source changes still
  need migration, stop rather than applying changes over it. Ask the user to
  choose a different target or handle the existing worktree.
- Resolve the target path with `gh qwt path <owner>/<repo>/<target-branch>`
  and verify it exists and `git -C <target> branch --show-current` equals the
  target branch.
- When source and target differ, require
  `git -C <target> status --porcelain` to be empty, then fetch `origin --prune`
  in the target. If `origin/<target-branch>` exists, compare it with local
  `HEAD` before any migration:
  - If local `HEAD` is behind and the target is clean, fast-forward with
    `git -C <target> merge --ff-only origin/<target-branch>`.
  - If local `HEAD` is ahead or diverged, stop rather than applying source
    changes to a stale or unrelated branch.
- If `gh qwt` reports a slash-prefix path collision, preserve all source
  state and stop. Do not work around it with a branch checkout.

#### Migrate uncommitted source changes safely

Skip this subsection when the source and target are the same worktree, or when
the recorded source status is empty. Otherwise migrate staged, unstaged, and
non-ignored untracked changes without changing branches.

1. Save the source status, staged binary diff, unstaged binary diff, and
   non-ignored untracked-file list in a private `mktemp -d` directory. Use
   these snapshots to validate the target after restoration.
2. Create a uniquely named stash with `git -C <source> stash push
   --include-untracked -m "copilot-pr-create-migration-<id>"`. Capture both
   the resulting stash object ID and a temporary ref such as
   `refs/copilot/pr-create-migration/<id>` that points to it with
   `git -C <source> update-ref <temporary-ref> <stash-object-id>`.
3. If source and target share a qwt common Git directory, restore with
   `git -C <target> stash apply --index <temporary-ref>`.
4. If the source is an ordinary clone, export the temporary ref with
   `git -C <source> bundle create <migration-dir>/migration.bundle <temporary-ref>`,
   fetch that bundle into the target under the same temporary ref, then run
   `git -C <target> stash apply --index <temporary-ref>`.
5. Compare the target's staged binary diff, unstaged binary diff, status, and
   untracked-file list with the snapshots from step 1. Also confirm that the
   source worktree is clean after stashing.
6. Only after all comparisons succeed:
   - Remove the temporary ref from every repository that received it.
   - Locate the exact stash reflog entry by its captured object ID and drop
     that entry. Do not assume it is still `stash@{0}`.
   - Remove the temporary migration directory.
7. If creating, fetching, applying, or validating the migration fails, stop
   immediately. Keep the source stash, temporary ref, and migration artifacts
   available for recovery, and report their locations. Do not discard changes
   or continue toward a PR.

### Step 4: Create a commit in the target worktree

- Run `git -C <target> diff --staged --quiet` and commit only when the exit
  code is 1, meaning staged files exist.
- Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
  format and write the commit message in English.
- Check recent commits with `git -C <target> log --no-merges --oneline -100`
  and follow the repository conventions.
- The commit subject must describe the change concretely.
  - Bad example: `docs: apply staged changes` (unclear what changed)
  - Bad example: `feat: update files` (too vague)
  - Good example: `feat: allow provided config object to extend other configs`
  - Good example: `fix(github): pin terraform-provider-github version to 6.6.0`
- The scope indicates the affected area, such as a directory name or action
  name. Use the imperative mood (`add`, `fix`, or `update`) to make the intent
  clear.
- Add supplementary explanation in the body when needed. You may split the
  work into multiple commits if it helps reviewability or logical separation.

### Step 5: Push the target branch

- Push only from the target worktree with
  `git -C <target> push --set-upstream origin <target-branch>`.
- Confirm that the target branch is the branch used for the PR. Never repair
  an accidental default-branch commit by rewriting the default branch.

### Step 6: Create the PR description and open a draft PR

- If `.github/pull_request_template.md` exists in the target worktree, follow
  its structure.
- Write the PR body in English.
- **Make full use of GitHub Flavored Markdown (GFM) features** so the body is
  readable, visually clear, and engaging:
  - **Tables** to organize structured information such as comparisons,
    before/after, or summaries of changes.
  - **Alerts** (`> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`,
    and `> [!CAUTION]`) to highlight key points, caveats, and breaking
    changes.
  - **Mermaid diagrams** to visualize flows, architecture, or sequences.
  - **Emoji** to add visual cues and make sections easy to scan.
  - Other GFM elements, such as task lists, collapsible `<details>`, and
    language-tagged code blocks, where they improve clarity.
  - Do not decorate for its own sake; use each element only when it genuinely
    improves clarity.
- Include the following in the description:
  - **Purpose:** What the PR accomplishes and why. If a task was confirmed or
    created in Step 1, include `closes #XXX`.
  - **Background:** The reason or context that made the change necessary,
    with a focus on what changes relative to the remote default branch.
- If `CONTRIBUTING.md` exists, follow its guidelines.
- Avoid simply listing changed files or relying on high-context explanations
  that omit the reason.
- Create the PR from the target worktree with `gh pr create --draft`.
  - The PR title must be in English and follow Conventional Commits:
    `<type>(<scope>): <description>`.
  - Use `feat` and `fix` only when the change directly affects the actual
    product deliverable. For build tooling, CI/CD configuration, or repository
    infrastructure, use `build`, `ci`, `chore`, or another accurate type.
  - Map labels to Conventional Commit types: `feat` -> `enhancement` and
    `fix` -> `bug`.
  - Do not use `enhancement` or `bug` labels for non-product-impacting
    changes. Use labels such as `documentation`, `chore`, `ci`, or `build`.

### Step 7: Assign the requesting user

- Set the user who invoked the skill as the PR assignee.
- Use `gh pr edit <PR_NUMBER> --add-assignee <username>` from the target
  worktree or with an explicit `-R <owner>/<repo>`.

### Step 8: Align the Issue (Task) description with the final changes

- If there is a corresponding task, update its description so its plan matches
  the final pull request changes.
- If, after iteration, the issue description no longer matches the actual
  changes:
  - Preserve the original plan as a comment with
    `gh issue comment <number>`.
  - Update it with `gh issue edit <number> --body` so it reflects the actual
    changes.
- If the description and actual changes matched from the start, do not rewrite
  it unnecessarily.

## Output

Open the URL of the created draft PR in the browser.
