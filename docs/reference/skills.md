# Agent Skills

This is the specification reference for custom skills shared by GitHub
Copilot, Codex, and Claude Code.

## Skill list

| Skill | Description |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `pr-create` | Create a draft PR from an isolated `gh-qwt` feature worktree, with an appropriate commit message and description |
| `pr-fix` | Use the PR head's `gh-qwt` worktree to fix CI errors and handle review comments |
| `pr-merge` | Loop enabled Copilot Code Review until there are no findings, request approval only when required, then merge and clean up the qwt branch workspace |

## Installation destination

`dotfiles/skills/` is the canonical source. When `install.sh` runs, each skill
directory is linked separately into every configured discovery root.

| Discovery root | Agents |
| -------------- | ------ |
| `~/.agents/skills/` | GitHub Copilot and Codex |
| `~/.claude/skills/` | Claude Code |

Missing discovery roots are created as real directories, and existing roots
are not replaced. Only their entries for `pr-create`, `pr-fix`, and `pr-merge`
are managed as links, so unrelated built-in and independently installed skills
remain untouched. The destinations are declared through `skill_targets`; see
[`install_map.json`](./install-map.md).

GitHub Copilot loads a same-named skill from `~/.copilot/skills/` before the
shared copy under `~/.agents/skills/`. The installer removes
`~/.copilot/skills` only when it is the former whole-directory link to this
repository and no configured replacement root is a whole-directory alias to
the canonical skills. It preserves real directories, links to other sources,
and the legacy link when deleting it could dangle a replacement alias. Remove
or rename a conflicting `pr-create`, `pr-fix`, or `pr-merge` entry in that
higher-priority root to select the canonical shared version. See GitHub's
[skill location priority](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#skills-reference).

## Canonical source layout

Each direct child of `dotfiles/skills/` that contains the required `SKILL.md`
is one installable skill directory. See the
[canonical skills directory](https://github.com/daiksud/dotfiles/tree/main/dotfiles/skills)
for the current files instead of reproducing their contents here.

> [!NOTE]
> This repository has no vendored skills at the moment. A skill installed
> directly from an upstream repository should be treated as synced content:
> use the same installation mechanism to update it instead of hand-editing the
> vendored files to match this specification.

## `SKILL.md` format specification

### Structure

Frontmatter is required. The section structure of the body can be freely defined according to the nature of the skill.

**Example of a simple skill (`pr-create` style):**

```markdown
---
description: Skill description (1 line, in English)
name: Skill name
---

# Skill name

## Overview

(What the skill does)

## When to use

(What kind of situations it is used in)

## Procedure

### Step 1: ...

### Step 2: ...

## Output

(What the skill outputs)
```

**Example of a skill with mode branching (`pr-fix` style):**

```markdown
---
description: Skill description (1 line, in English)
name: Skill name
---

# Skill name

## Usage

(How to invoke it and an explanation of each mode)

## Modes

### mode-a — ...

### mode-b — ...

## Common steps

(Processing performed in all modes)

## Constraints

(Constraints)
```

### Frontmatter (required)

| Field | Type | Description |
| ------------- | ------ | ----------------------------------------------- |
| `name` | string | Skill identifier. Must match the directory name |
| `description` | string | Skill summary used for discovery and agent selection |

### Language used in the body

- Write the frontmatter `description` in **English** (used for discovery and selection)
- Write the body in **English**

### Portability requirements

- Describe when the skill applies in `description`; do not depend on one
  product's slash-command mapping for discovery.
- Refer to another shared skill by its name, such as “use the `pr-fix` skill”.
  Do not embed a product-specific invocation such as `/pr-fix` in the canonical
  procedure.
- Use capability-based language for optional helpers. For example, request a
  dedicated review skill or review subagent when the host provides one, then
  define a provider-independent fallback.
- Keep hooks, manifests, permissions, and proprietary integration settings out
  of shared skill files. Those remain in vendor-specific configuration.
- Proper names for external services, such as Copilot Code Review, are allowed
  when the workflow genuinely depends on that service.

### Section guidelines

| Section | Required | Description |
| -------------------- | ----------- | ---------------------------------------------------- |
| Overview or Usage | ✅ | Explain the purpose of the skill or how to invoke it |
| Procedure or Modes | ✅ | Step-by-step or mode-specific operating procedure |
| Constraints | Recommended | Constraints and behavior on failure |
| Output | Recommended | What is shown to the user when the skill finishes |
| Hints for developers | Optional | Example alias configuration, etc. |

## PR workspace policy

The three PR skills use [`gh-qwt`](./gh-qwt.md) as their only
branch-workspace mechanism. A branch is represented by its own worktree, not
by changing the branch of the invoking checkout.

- Every skill resolves the remote through GitHub and records its canonical URL
  plus the full lowercase `<host>/<owner>/<repo>` identity. A managed
  repository stores the same value as its repository-local `qwt.identity`, so
  before the skill lists, fetches, reuses, pushes, or removes an existing
  checkout, the recorded identity must match both `qwt.identity` and the
  expanded `origin` URL. A mismatch stops the skill instead of rewriting
  `origin`; repositories that must stay apart are separated with distinct ghq
  roots.
- The skills resolve a target with `gh qwt path`, using a host-qualified
  `<host>/<owner>/<repo>/<branch>` spec for a branch, and run repository
  commands against that absolute path.
- A resolved path is never treated as proof of existence, because `gh qwt path`
  also prints the planned path of a worktree that has not been created yet.
  Before reusing a target, and after each `get` or `add`, the skills require an
  unfiltered `gh qwt list --all <spec> --exact --full-path` result to contain
  the worktree created by that command byte-for-byte, and they require
  `qwt.managed` in the resolved checkout. A primary-checkout bootstrap `get` is
  checked before a feature-branch `add`; the feature target is checked after
  `add`. An occupied path without exact registration is a collision, not a
  worktree. An occupied repository path without managed metadata is likewise a
  collision, not a repository to adopt in place.
- A missing repository is provisioned with `gh qwt get`. A missing branch
  worktree in an existing repository is created with `gh qwt add`.
  `get --branch` is used only for an existing remote branch; creating a new
  branch first requires `get` for the default branch, followed by `add`.
  Provisioning passes the verified host explicitly with `get --host`, then
  verifies the new checkout's managed metadata before it is used.
- Before `add` runs in an existing repository, the skills refresh
  `origin --prune` from the primary checkout so cached refs cannot turn a
  just-pushed branch into a mistakenly new branch.
- Before a PR skill edits a reused target, it requires a clean worktree and
  either fast-forwards it to its remote head or stops on an ahead/diverged
  branch. It never silently overwrites an existing worktree.
- The skill procedures must not use `git switch`, `git checkout`, ordinary
  `git worktree`, or a normal-clone fallback.
- If qwt cannot safely create a worktree, such as a slash-prefix path
  collision, the skill reports the error and stops. It does not change the
  branch of another checkout as a workaround.
- This restriction applies to PR skills only. Interactive shell Git commands
  remain unchanged.

`pr-create` preserves uncommitted source changes through a named stash and
verification before it clears the source. When the source is a checkout that
gh-qwt does not manage, the stash is transferred as a temporary Git bundle so
staged, unstaged, and non-ignored untracked changes retain their state in the
qwt target. A default branch with local commits is intentionally not reset,
rebased, or pushed by the skill; it stops and asks for explicit direction
instead.

## Detailed specification for `pr-create`

### Workflow

1. Check the corresponding Task (Issue) (if it cannot be inferred, ask the user to confirm; if there is none, encourage them to create one)
2. Understand the source changes with `git diff` and the Issue description and comments
3. Resolve or create the feature branch's qwt worktree, migrating uncommitted changes only through the verified preservation procedure
4. Stage the intended uncommitted paths and commit from the target worktree
   using the Conventional Commits format
5. Push the target branch
6. Create the PR description (write a readable, visually clear body that fully leverages GFM features such as tables, alerts, Mermaid, and emoji), then create a draft PR with `gh pr create --draft`
7. Set the invoking user as the Assignee
8. Finally, update the corresponding Task description to match the final changes (move the original plan to a comment)

### Input

- Intended changes that are already committed, staged, unstaged, or present as
  non-ignored untracked files
- Optional: reason for the change, related Issue number

### Output

- URL of the created draft PR

## Detailed specification for `pr-fix`

### Workflow

1. Resolve the base repository and the PR head repository / branch, then create or reuse the head qwt worktree
2. Check the CI status of the specified PR
3. If there are CI failures, analyze the logs and repeat fixes (up to 3 times)
4. Retrieve all review comments and judge the validity of each one
5. Fix valid comments and skip invalid ones; for comments the user replied "対応しない" (will not address) to, record in the PR body that they will not be addressed along with the reason
6. Before committing and pushing, perform an independent local review. Use a dedicated review skill or review subagent when the host provides one; otherwise make a separate review pass over the full diff
7. After pushing, reply to each review comment with how it was addressed
8. Query the active rules for the PR base branch and request Copilot Code
   Review only when an effective `copilot_code_review` rule exists

The PR API remains scoped to the base repository. Git changes and pushes occur
only in the head worktree. For a fork PR, the head repository is used as the
qwt target; a deleted fork or missing push access stops the skill instead of
creating a substitute branch in the base repository.

### Input

- PR number (required)

### Output

- Replies to each review comment
- Whether Copilot Code Review was requested or skipped because it is disabled
- Error report if CI still does not pass

## Detailed specification for `pr-merge`

### Workflow

`pr-merge` runs a single retry loop (up to 10 iterations) per PR:

1. Query the active rules for the PR base branch. If they include
   `copilot_code_review`, use the `pr-fix` skill in `all` mode, request a
   Copilot Code Review, and wait for it to complete. Otherwise, run `pr-fix`
   but skip the review request and wait
2. When Copilot Code Review is enabled, count its unresolved findings
   (paginated `reviewThreads`, filtered to
   `copilot-pull-request-reviewer`); if any remain, go back to step 1
3. Mark the PR ready for review (`gh pr ready`) and query GitHub's computed
   `reviewDecision`. Skip approval when it is null or empty, reuse an existing
   valid approval when it is `APPROVED`, or apply the `self approval` label
   once when review is required
4. When review is required, wait for the pre-existing self-approval automation
   to make `reviewDecision` become `APPROVED` (short 3-minute timeout measured
   from the one persistent request). Re-check the decision after retries and
   reuse an approval only while GitHub continues to report it as valid
5. Wait for CI to go green and re-check mergeability; a merge conflict or a CI failure sends control back to step 1 because the `pr-fix` skill can fix both
6. Once CI is green and there are no conflicts, verify that the qwt worktree
   is clean and still matches the PR head, squash merge with the checked head
   SHA, then remove the qwt worktree and local branch with `gh qwt remove
   --delete-branch`

The active-rules query is evaluated per PR against its canonical base host and
base branch. A failed query stops that PR rather than being interpreted as an
absent `copilot_code_review` rule.

After the qwt cleanup, `pr-merge` deletes the head remote branch directly from
its repository only when it still equals the verified PR head SHA. The
lease-protected deletion works for both same-repository and fork PRs, while
avoiding the branch checkout that GitHub CLI can otherwise perform during
local branch deletion. The explicit
`gh qwt remove <host>/<owner>/<repo>/<branch>` command runs from outside the
repository so its argument cannot be mistaken for a branch name.

Multiple PR numbers are processed one at a time; a PR that fails or times out is skipped (recorded) so the rest of the batch still runs.

> [!NOTE]
> When GitHub reports that review is required, `pr-merge` assumes an automation
> that approves PRs labeled `self approval` and the label itself already exist.
> It does not create either one. Repositories where `reviewDecision` is null or
> empty do not need that automation or label for this workflow.

### Input

- One or more PR numbers (required)

### Output

- The merged PR's URL for each successfully merged PR
- The failure reason (which step, and why) for any PR that could not be merged
- Whether Copilot Code Review or self approval was skipped as unnecessary
- A final summary across all given PR numbers
