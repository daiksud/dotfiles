# Agent Skills

This is the specification reference for custom skills shared by GitHub
Copilot, Codex, and Claude Code.

## Skill list

| Skill | Description |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `herdr-subagents` | Run one or more coding subagents in Herdr panes or tabs, preserving focus and collecting results |
| `pr-create` | Create a draft PR from the current checkout, with an appropriate commit message and description |
| `pr-fix` | Use the checkout of the PR head branch to fix CI errors and handle review comments |
| `pr-merge` | Merge one PR from the checkout of its checked-out head |

## Installation destination

`dotfiles/skills/` is the canonical source. When `install.sh` runs, each skill
directory is linked separately into every configured discovery root.

| Discovery root | Agents |
| -------------- | ------ |
| `~/.agents/skills/` | GitHub Copilot and Codex |
| `~/.claude/skills/` | Claude Code |

Missing discovery roots are created as real directories, and existing roots
are not replaced. Only their entries for `herdr-subagents`, `pr-create`,
`pr-fix`, and `pr-merge` are managed as links, so unrelated built-in and
independently installed skills remain untouched. The destinations are declared
through `skill_targets`; see [`install_map.json`](./install-map.md).

GitHub Copilot loads a same-named skill from `~/.copilot/skills/` before the
shared copy under `~/.agents/skills/`. The installer removes
`~/.copilot/skills` only when it is the former whole-directory link to this
repository and no configured replacement root is a whole-directory alias to
the canonical skills. It preserves real directories, links to other sources,
and the legacy link when deleting it could dangle a replacement alias. Remove
or rename a conflicting `herdr-subagents`, `pr-create`, `pr-fix`, or
`pr-merge` entry in that higher-priority root to select the canonical shared
version. See GitHub's
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
- Keep manifests, permissions, and proprietary integration settings out of
  shared skill files. Those remain in vendor-specific configuration.
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

## PR checkout policy

The three PR skills operate in the Git checkout where the user invokes them.
That checkout may be an ordinary clone, a gh-qw main worktree, or a linked
worktree. They do not create or use `gh-qw`, `git worktree`, or another
checkout.

- Every skill resolves the relevant remote through GitHub and records its
  canonical URL and lowercase `<host>/<owner>/<repo>` identity before GitHub
  API calls, pushes, or merges. An identity mismatch stops the workflow rather
  than rewriting `origin`.
- `pr-create` may create a feature branch in the invoking checkout only when
  its default-branch `HEAD` exactly matches the remote default branch. It
  preserves intended staged, unstaged, and non-ignored untracked changes during
  that branch creation. A default branch that is ahead, behind, or diverged
  stops rather than being pulled, rebased, reset, or used as an uncertain base.
- Before creating a branch, `pr-create` checks `git worktree list --porcelain`
  and stops with the registered path if another checkout already has the target
  branch.
- A non-default branch used by `pr-create` must not already correspond to an
  open, closed, or merged PR. This prevents accidental reuse of a branch left
  checked out after a squash merge.
- `pr-fix` and `pr-merge` require a clean invoking checkout of the exact PR
  head branch and repository. A fork PR requires a checkout of the fork and a
  PR URL or explicit base repository; the skills report the canonical URL and
  branch when the caller must prepare one.
- Before commits, pushes, and merges, especially after polling waits, the
  skills re-check the current branch, working state, remote head, and expected
  PR SHA. They stop on an unsafe or concurrent change.
- `pr-merge` accepts one PR per invocation. It leaves the local head branch
  checked out after a successful merge and only deletes the remote head branch
  when its ref still equals the verified PR head SHA.
- Concurrent PR work requires separate checkouts, such as linked worktrees or
  ordinary clones. The policy does not change normal interactive Git usage.

See [ADR 0021](../development/99-adr/0021-pr-skills-invoking-checkout.md) and
[ADR 0027](../development/99-adr/0027-gh-qw.md) for the
rationale.

## Detailed specification for `pr-create`

### Workflow

1. Check the corresponding Task (Issue) (if it cannot be inferred, ask the user to confirm; if there is none, encourage them to create one)
2. Understand the source changes with `git diff` and the Issue description and comments
3. Create a feature branch in the current checkout only when its default
   branch exactly matches its remote; otherwise use a non-default branch that
   has no existing PR
4. Stage the intended uncommitted paths and commit from the current checkout
   using the Conventional Commits format
5. Push the current branch
6. Create the PR description (write a readable, visually clear body that fully
   leverages GFM features such as tables, alerts, Mermaid, and emoji), then
   create a draft PR with explicit verified `-R`, `--base`, and `--head` values
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

1. Resolve the base repository and PR head, then require a clean current
   checkout of the exact head repository and branch
2. Check the CI status of the specified PR
3. If there are CI failures, analyze the logs and repeat fixes (up to 3 times)
4. Retrieve all review comments and judge the validity of each one
5. Fix valid comments and skip invalid ones; for comments the user replied "対応しない" (will not address) to, record in the PR body that they will not be addressed along with the reason
6. Before committing and pushing, perform an independent local review. Use a dedicated review skill or review subagent when the host provides one; otherwise make a separate review pass over the full diff
7. After pushing, reply to each review comment with how it was addressed
8. Query the active rules for the PR base branch and request Copilot Code
   Review only when an effective `copilot_code_review` rule exists

The PR API remains scoped to the base repository. Git changes and pushes occur
only in the invoking checkout. For a fork PR, it must be a checkout of the
head repository; a deleted fork or missing push access stops the skill instead
of creating a substitute branch in the base repository.

### Input

- PR URL, or PR number with host-qualified base repository (required)

### Output

- Replies to each review comment
- Whether Copilot Code Review was requested or skipped because it is disabled
- Error report if CI still does not pass

## Detailed specification for `pr-merge`

### Workflow

`pr-merge` runs a single retry loop (up to 10 iterations) for one PR:

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
6. Once CI is green and there are no conflicts, verify that the current
   checkout is clean and still matches the PR head, then squash merge with the
   checked head SHA

The active-rules query is evaluated per PR against its canonical base host and
base branch. A failed query stops that PR rather than being interpreted as an
absent `copilot_code_review` rule.

After the merge, `pr-merge` leaves the local head branch checked out. It deletes
the head remote branch directly only when its ref still equals the verified PR
head SHA. The lease-protected deletion works for both same-repository and fork
PRs without switching or deleting the local branch.

> [!NOTE]
> When GitHub reports that review is required, `pr-merge` assumes an automation
> that approves PRs labeled `self approval` and the label itself already exist.
> It does not create either one. Repositories where `reviewDecision` is null or
> empty do not need that automation or label for this workflow.

### Input

- One PR URL, or PR number with host-qualified base repository (required)

### Output

- The merged PR URL
- The failure reason and step when it could not be merged
- Whether Copilot Code Review or self approval was skipped as unnecessary
