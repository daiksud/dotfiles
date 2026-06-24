---
name: pr-create
description: A skill used when creating a Pull Request. This also applies when `/pr create` is invoked. It creates a draft PR according to the repository conventions.
---

# pr-create

## Overview

This is a skill for creating a draft Pull Request (PR).
It understands staged files and committed changes, then creates the PR with an appropriate commit message and PR description.

## When to use

- When asked to "create a PR"
- When `/pr-create` or `/pr create` is invoked in GitHub Copilot CLI

## Procedure

### Step 1: Check the corresponding Task (GitHub Issue)

- First, check whether there is a GitHub Issue (Task) corresponding to this change
  - Infer the related issue from the context at skill invocation time, the branch name, commit messages, and so on
  - If you can infer it, inspect it with `gh issue view <number> --comments` and verify that it matches the changes
    - Read not only the issue description but also the comments to understand the intent, background, and flow of discussion
- If the corresponding task cannot be inferred easily, ask the user
  - Example: "Is there a Task (Issue) associated with this change? If so, please tell me the number."
- If there is no corresponding task, encourage the user to create one
  - If creating a task, suggest `gh issue create`
  - After creating the task, note its number and use it in a later step (`closes #XXX` in the PR description)

### Step 2: Understand the changes deeply

- Run `git diff --staged` or `git diff origin/main..` and review the full diff
- Read the diff for each file and understand **what** changed and **why**
  - Always focus on what changes will be applied relative to `origin/main`
- Consider the context and reasons provided when the skill was invoked
- When inferring the change details or background, also refer to the corresponding issue description and comments
- For new files, read the entire file to understand its purpose and role
- If the changes span multiple logical units, consider splitting them into multiple commits

### Step 3: Create a commit message and commit

- Run `git diff --staged --quiet` and commit only when the exit code is 1 (meaning there are staged files)
- Follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format
- Write the commit message in English
- Check recent commits with `git log --no-merges --oneline -100` and follow the repository conventions
- **The commit subject must describe the change concretely**
  - Bad example: `docs: apply staged changes` (unclear what changed)
  - Bad example: `feat: update files` (too vague)
  - Good example: `feat: allow provided config object to extend other configs`
  - Good example: `fix(github): pin terraform-provider-github version to 6.6.0`
- The scope indicates the affected area (such as a directory name or action name)
- Use the imperative mood (`add`, `fix`, `update`) to make the intent clear
- Add supplementary explanation in the body when needed
- You may split the work into multiple commits if it helps reviewability or logical separation

### Step 4: Push to a feature branch

- If you are currently on `main`, create and check out a feature branch
- The branch name should reflect the changes (for example, `feat/add-pr-create-skill`, `fix/pin-terraform-provider-github-660`)
- Map branch prefixes to Conventional Commit types: `feat` -> `feat/*`, `fix` -> `fix/*`, `docs` -> `docs/*`
- Do **not** use `feat/*` or `fix/*` branch names for changes that do not affect the actual product deliverable (for example, build tooling, CI/CD configuration, or repository infrastructure changes)
- For non-product-impacting changes, use a branch prefix that matches the real change type (for example, `docs/*`, `chore/*`, `ci/*`, `build/*`)
- Push with `git push --set-upstream origin <branch>`
- If you accidentally committed on the local `main` branch, restore it to match `origin/main`

### Step 5: Create the PR description and open a draft PR

- If `.github/pull_request_template.md` exists, follow its structure
- Write the PR body in English
- **Make full use of GitHub Flavored Markdown (GFM) features** so the body is readable, visually clear, and engaging:
  - **Tables** to organize structured information such as comparisons, before/after, or summaries of changes
  - **Alerts** (`> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`) to highlight key points, caveats, and breaking changes
  - **Mermaid diagrams** to visualize flows, architecture, sequences, or relationships
  - **Emoji** to add visual cues and make sections easy to scan
  - Other GFM elements (task lists, collapsible `<details>`, code blocks with language hints, etc.) wherever they aid comprehension
  - Do not decorate for its own sake — use each element only when it genuinely improves clarity
- Include the following in the description:
  - **Purpose:**
    - What this PR accomplishes, including not only **what** but also **why**
    - If there is a task confirmed or created in Step 1, include `closes #XXX`
  - **Background:**
    - The reason or context that made this change necessary
    - Be sure to explain it with a focus on what changes relative to `origin/main`
- If `CONTRIBUTING.md` exists, follow its guidelines
- Avoid the following anti-patterns
  - Simply listing "changed files" as-is (do not write what is already obvious from the diff)
  - High-context explanations that do not state the reason
- Create the PR with `gh pr create --draft`
  - The **PR title** must be in English and follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) format: `<type>(<scope>): <description>`
  - Use `feat` and `fix` **only** when the change directly affects the actual product (deliverable) — i.e., a new feature visible to end users or a bug fix that changes runtime behavior. Do **not** use `feat` or `fix` for changes that have no product impact, such as adding build tooling, fixing CI/CD configuration, or updating repository infrastructure. Use `build`, `ci`, `chore`, or another appropriate type instead.
  - Map labels to Conventional Commit types: `feat` -> `enhancement`, `fix` -> `bug`
  - Do **not** use `enhancement` or `bug` labels for new features or bug fixes that do not affect the actual product deliverable (for example, build tooling, CI/CD configuration, or repository infrastructure changes)
  - For non-product-impacting changes, use labels that match the real change type (for example, `documentation`, `chore`, `ci`, `build`)

### Step 6: Assign the requesting user

- Set the user who invoked the skill as the PR assignee
- Use `gh pr edit <PR_NUMBER> --add-assignee <username>`

### Step 7: Align the Issue (Task) description with the final changes

- If there is a corresponding task, update its description so its plan matches the final pull request changes
- If, after iteration, the issue description no longer matches the actual changes:
  - Preserve the original plan (the original description) as a comment with `gh issue comment <number>`
  - Then update the issue description with `gh issue edit <number> --body` so it reflects the actual changes
- If the description and the actual changes matched from the start, there is no need to rewrite it unnecessarily

## Output

Open the URL of the created draft PR in the browser.
