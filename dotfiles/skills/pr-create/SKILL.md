---
name: pr-create
description: Create a draft GitHub Pull Request from current committed or uncommitted changes in an isolated gh-qwt worktree while preserving source state and following repository conventions. Use only when the user explicitly asks to create, open, prepare, or draft a PR. Within that PR workflow, migrate changes, commit, push, associate an issue, write the description, and assign the requester as needed. Do not use for standalone branch migration, commit, push, issue, or assignment requests without PR intent.
---

# pr-create

## Overview

Create a draft Pull Request (PR) from the current changes. Use `gh-qwt` to
give the PR branch its own worktree rather than switching branches in a shared
checkout.

## Workspace rules

- `gh qwt` is the only workspace mechanism for this skill. If it is
  unavailable, the repository is not hosted on GitHub, or qwt cannot create
  the requested path, stop and report the problem.
- Never run `git switch`, `git checkout`, `git worktree`, or a branch-switching
  fallback in the primary checkout or any other clone. Create and select
  branches only through `gh qwt get` and `gh qwt add`.
- Resolve the target with `gh qwt path <host>/<owner>/<repo>/<branch>` and run
  every repository command against that absolute path, for example
  `git -C "$worktree" status`. Do not rely on the invoking directory after the
  target worktree has been selected. Every `gh qwt path` spec must be
  host-qualified (`github.com/<owner>/<repo>[/<branch>]` for GitHub.com);
  `gh qwt path` reads a three-segment spec as `<host>/<owner>/<repo>`, so a
  bare `<owner>/<repo>/<branch>` resolves to the wrong identity and fails.
- `gh qwt` keeps the primary checkout as an ordinary clone at
  `<ghq-root>/<host>/<owner>/<repo>` and every non-default branch as an
  external linked worktree at
  `<qwt.worktreeroot>/<host>/<owner>/<repo>/<branch>`, which defaults to
  `<ghq-root>-worktrees`. The default branch has no linked worktree: it is the
  primary checkout itself.
- Treat repository identity as the canonical GitHub URL plus the canonical
  `<owner>/<repo>` qualified by its lowercase host. Those paths are
  host-qualified, but the same `<owner>/<repo>` can still exist on several
  hosts and `path`, `list --exact`, `add --repo`, and `remove --repo` all
  accept short `<owner>/<repo>` specs that silently mean `github.com`. Never
  list, fetch, add to, or reuse an existing managed repository until its
  primary-checkout `origin` and `qwt.identity` have passed the identity guard
  in Step 3.
- Never use `git reset --hard`, force-push, or `gh qwt remove --force` to move
  changes. An unsafe migration must stop with the source worktree or an
  identifiable stash intact.

## Procedure

### Step 1: Check the corresponding Task (GitHub Issue)

- First, check whether there is a GitHub Issue (Task) corresponding to this
  change.
  - Infer the related issue from the request context, the
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

- Treat the checkout in which the request originated as the **source
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
- Consider the context and reasons provided in the request. When
  inferring the change details or background, also refer to the corresponding
  issue description and comments.
- If the changes span multiple logical units, consider splitting them into
  multiple commits.

### Step 3: Prepare the qwt feature worktree

#### Resolve the repository and source state

1. Confirm that `gh qwt --help` succeeds.
2. Read the selected source remote's expanded fetch URL and resolve it through
   GitHub. Record the returned canonical repository URL, its lowercase host,
   the canonical `nameWithOwner`, and the default branch. Do not infer
   `github.com` from an unqualified repository name. Also record:
   - `git -C <source> branch --show-current`
   - `git -C <source> rev-parse HEAD`
3. Stop if `HEAD` is detached, the repository cannot be resolved by `gh`, or
   the source branch, canonical URL, host, owner, repo, or default branch cannot
   be determined.
4. Calculate the primary checkout path with `gh qwt path <host>/<owner>/<repo>`.
   Treat the managed repository as existing only when
   `git -C <primary-checkout> config --get qwt.managed` prints exactly `true`.
   A clone that carries no `qwt.managed` metadata is not a managed repository,
   and `gh qwt path` also prints deterministic planned paths for repositories
   and worktrees that do not exist yet. If the calculated repository path is
   occupied but is not a `qwt.managed` repository, stop and report a
   repository-path collision; do not run `get` inside it.
5. If the managed repository exists, guard its identity before inspecting or
   operating on it:
   - Read the expanded fetch URL for `origin` from its primary checkout with
     `git -C "$(gh qwt path <host>/<owner>/<repo>)" remote get-url origin` and
     resolve that URL through GitHub.
   - Require both its canonical repository URL and its full
     `<lowercase-host>/<canonical-owner>/<canonical-repo>` identity to equal
     the values recorded from the source remote, and require
     `git -C <primary-checkout> config --get qwt.identity` to equal that same
     `<host>/<owner>/<repo>` identity.
   - Stop if either side cannot be verified or differs. Do not list or fetch
     the repository, rewrite `origin`, add a worktree, or reuse any existing
     worktree. Report the host collision and require a separately configured
     ghq root (`GHQ_ROOT` or `ghq.root`) or manual resolution.
6. Before using `gh qwt add` in an existing repository, and only after it
   passes the guard, refresh its branch metadata with:

   ```bash
   git -C "$(gh qwt path <host>/<owner>/<repo>)" fetch origin --prune
   ```

   This is the narrow exception to target-worktree command scoping: `gh qwt
   add` consults cached branch refs and does not fetch them itself.

#### Choose the target branch and create its worktree

- If the source appears to be the qwt worktree for a non-default feature
  branch, select it as the target candidate. It must still pass the exact qwt
  registration check below; do not trust the calculated path or Git branch
  alone.
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
- After selecting the target branch, calculate its absolute path again. When
  the guarded managed repository exists, run
  `gh qwt list --all <host>/<owner>/<repo>/<target-branch> --exact --full-path`
  without output filtering and require the command to succeed. Pass `--all`
  because an unqualified `gh qwt list` is scoped to the repository containing
  the current directory and fails with
  `gh-qwt: repository is outside configured ghq roots` when that directory is
  a Git repository outside the configured ghq roots. Treat the target as a
  registered worktree only when at least one stdout line equals the calculated
  target path byte-for-byte; ignore other lines, because `--exact` also
  matches a bare `<branch>`, `<repo>/<branch>`, and `<owner>/<repo>/<branch>`
  in every listed repository. If it is unregistered but the
  calculated path is occupied by any file, directory, or link, stop and report
  a path collision. When the managed repository is missing, likewise stop before
  `get` if the calculated target path is already occupied. In the steps below,
  “target worktree exists” means this exact registration check succeeded.
- Before migrating a default-branch source, fetch its default branch and
  compare `HEAD` with `origin/<default-branch>`.
  - If the default branch has local commits or the base does not match, stop.
    Do not reset, rebase, or push the default branch automatically.
  - The target branch must be new. If a local or remote branch with the chosen
    target name already exists in the managed repository, stop rather than
    applying the default-branch changes to it.
- For a non-default source that does not share the managed repository's Git
  common directory, meaning
  `git -C <source> rev-parse --path-format=absolute --git-common-dir` differs
  from `<primary-checkout>/.git`, publish its committed branch
  with `git -C <source> push --set-upstream origin <source-branch>` before
  creating its qwt counterpart. This transfers committed work without a
  checkout. Stop if the push is rejected.
- If the managed repository does not yet exist:
  - For an existing remote target branch from a non-default source, run
    `gh qwt get --host <host> --branch <target-branch> <owner>/<repo>`.
  - For a new target branch, run
    `gh qwt get --host <host> --branch <default-branch> <owner>/<repo>` first,
    which prints the primary checkout.
  - After either provisioning command, immediately resolve the new primary
    checkout's `origin` through GitHub and require the same canonical URL
    and full host/owner/repo identity recorded above, plus a matching
    `git -C <primary-checkout> config --get qwt.identity`. If verification
    fails, stop before listing, fetching, adding, or reusing it; do not rewrite
    `origin`.
  - For a new target branch only, and only after that verification, require an
    unfiltered
    `gh qwt list --all <host>/<owner>/<repo>/<default-branch> --exact --full-path`
    result to contain the primary checkout path byte-for-byte. The default
    branch is the primary checkout, so both
    `gh qwt path <host>/<owner>/<repo>` and
    `gh qwt path <host>/<owner>/<repo>/<default-branch>` resolve to it. Verify
    that path is a directory on the default branch, then run
    `gh qwt add --repo <host>/<owner>/<repo> --new --from origin/<default-branch> <target-branch>`.
- If the managed repository exists but the target worktree does not, run
  `gh qwt add --repo <host>/<owner>/<repo> <target-branch>`, which reattaches
  an existing local branch and otherwise tracks an existing remote branch.
  When the target branch must be genuinely new, run
  `gh qwt add --repo <host>/<owner>/<repo> --new --from origin/<default-branch> <target-branch>`
  instead: `--from` applies only on the path where `add` creates the branch
  itself, and `--new` fails instead of attaching an existing local or remote
  branch. `add` cannot create a worktree for the default branch, which is the
  primary checkout.
- If a separate target worktree already exists while source changes still
  need migration, stop rather than applying changes over it. Ask the user to
  choose a different target or handle the existing worktree.
- After a `get` that directly creates the target branch, after every `add`, and
  again before migration, resolve the target path and repeat the exact
  unfiltered `gh qwt list --all` check above. Between the default-branch `get`
  used to initialize a new repository and the subsequent target-branch `add`,
  check the primary checkout's registration as specified above; the target is
  checked only after `add`. Require the calculated target path to appear
  byte-for-byte after the applicable creation step, then verify it is a
  directory and `git -C <target> branch --show-current` equals the target
  branch. Stop if registration is missing; never reuse an occupied
  unregistered path.
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
   --include-untracked -m "agent-pr-create-migration-<id>"`. Capture both
   the resulting stash object ID and a temporary ref such as
   `refs/agent/pr-create-migration/<id>` that points to it with
   `git -C <source> update-ref <temporary-ref> <stash-object-id>`.
3. If the source and target share the managed repository's Git common
   directory, meaning
   `git -C <path> rev-parse --path-format=absolute --git-common-dir` returns
   `<primary-checkout>/.git` for both, restore with
   `git -C <target> stash apply --index <temporary-ref>`.
4. If the source has a different Git common directory, export the temporary ref
   with
   `git -C <source> bundle create <migration-dir>/migration.bundle <temporary-ref>`,
   fetch that bundle into the target under the same temporary ref, then run
   `git -C <target> stash apply --index <temporary-ref>`. The fetched objects
   and ref land in the managed repository's shared `.git`, because every linked
   worktree uses the primary checkout's object database.
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

- Confirm which target changes belong in the PR based on the scope established
  in Step 2. If the target contains unrelated changes, ask the user which paths
  to include instead of staging them silently.
- Stage every intended uncommitted path explicitly, including selected
  unstaged and non-ignored untracked files restored during migration. Use
  `git add -A` only when the user has confirmed that the entire target state
  belongs in this PR.
- Inspect the full staged diff and verify it matches the intended scope. Then
  run `git -C <target> diff --staged --quiet` and interpret the exit status:
  - Exit 1 means staged changes exist; commit them.
  - Exit 0 means there is nothing to commit. Continue only when the intended
    changes are already committed on the target branch relative to the PR base;
    otherwise stop instead of creating an empty PR.
  - Any other exit status is an error; stop and report it.
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

- Set the requesting user as the PR assignee.
- Use `gh pr edit <PR_NUMBER> --add-assignee <username>` from the target
  worktree or with an explicit `-R <host>/<owner>/<repo>`.

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
