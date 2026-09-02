# Agent Skills

This is the specification reference for custom skills shared by GitHub
Copilot, Codex, and Claude Code.

## Skill list

| Skill | Description |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `pr-create` | Create a draft PR from the current checkout, with an appropriate commit message and description |
| `pr-fix` | Create or reuse a per-PR worktree checked out from the remote head to fix CI errors and handle review comments |
| `pr-merge` | Create per-PR worktrees, then merge one or more PRs after review and required CI checks |

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

When `install.sh` is re-run, it removes stale symbolic links to canonical skill
directories whose `SKILL.md` no longer exists. Real directories and links to
other sources are preserved.

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

The three PR skills use the Git checkout where the user invokes them for
repository context. `pr-create` keeps that checkout as its only workspace,
while `pr-fix` and `pr-merge` create or reuse a deterministic worktree for
each PR with the native `gh pr checkout --worktree` command. The source
checkout may be an ordinary clone, a gh-qw main worktree, or a linked
worktree, and its branch and files remain unchanged by the maintenance and
merge workflows.

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
- `pr-fix` and `pr-merge` resolve the PR head, derive
  `<repository-parent>/.pr-worktrees/<base-host>/<base-owner>/<base-repo>/pr-<PR_NUMBER>`,
  and run `gh pr checkout <PR_NUMBER> -R <base-repository> --worktree
  <target-worktree>` before changing files. A clean, registered target
  worktree is reused; an unregistered path, branch collision, stale SHA, or
  unavailable push remote stops the workflow without a force operation.
- The target worktree is checked against the remote PR `headRefOid` before
  editing and before every push or merge. Its configured push destination, or
  the canonical head URL when no destination is configured, must resolve to
  the PR head repository, including for fork PRs.
- Batch `pr-merge` accepts multiple PR numbers or `all`, keeps the invoking
  checkout untouched, and creates one isolated worktree per PR instead of
  switching between local branches. Fork heads use the same worktree flow; a
  deleted head repository or unavailable push access is reported per PR.
- Before commits, pushes, and merges, especially after polling waits, the
  skills re-check the target worktree, working state, remote head, and expected
  PR SHA. They stop on an unsafe or concurrent change.
- `pr-fix` and `pr-merge` retain each clean PR worktree for later reuse. Both
  modes delete a remote head branch only when its ref still equals the
  verified PR head SHA.
- Batch PRs run sequentially in separate worktrees while the source checkout
  remains available for unrelated interactive work. The policy does not
  change normal interactive Git usage.

See [ADR 0021](../development/99-adr/0021-pr-skills-invoking-checkout.md),
[ADR 0027](../development/99-adr/0027-gh-qw.md),
[ADR 0033](../development/99-adr/0033-pr-merge-batch-processing.md),
[ADR 0035](../development/99-adr/0035-pr-skills-dedicated-worktrees.md), and
[ADR 0036](../development/99-adr/0036-pr-review-availability.md) for the
rationale.

## Local GitHub comment policy

Organization-specific comment prefixes are read from
`$XDG_CONFIG_HOME/dotfiles/agent.toml`, or
`~/.config/dotfiles/agent.toml` when `XDG_CONFIG_HOME` is unset. The file uses
a TOML table where each GitHub organization maps to the prefix that should be
followed by one space:

```toml
[github.comment_prefixes]
"your-organization" = ":robot:"
```

The personal instructions and `pr-fix` consult this table before posting
comments. A missing organization entry means that no organization-specific
prefix is added. A present but unreadable or invalid file is a configuration
error and must be reported before posting.

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

`pr-create` does not request Copilot Code Review or apply the `self approval`
label. Those optional review and merge decisions belong to later `pr-fix` or
`pr-merge` runs.

## Detailed specification for `pr-fix`

### Workflow

1. Resolve the base repository and PR head, then create or reuse the
   deterministic PR-number worktree from the remote head
2. Check the CI status of the specified PR
3. If there are CI failures, analyze the logs and repeat fixes (up to 3 times)
4. Retrieve all review comments and judge the validity of each one
5. Fix valid comments and skip invalid ones; for comments the user replied "対応しない" (will not address) to, record in the PR body that they will not be addressed along with the reason
6. Before committing and pushing, perform an independent local review. Use a dedicated review skill or review subagent when the host provides one; otherwise make a separate review pass over the full diff
7. Before replying, consult the local GitHub comment policy and apply the
   configured organization prefix when one exists; after pushing, reply to each
   review comment with how it was addressed
8. Query the active rules for the PR base branch and request Copilot Code
   Review only when an effective `copilot_code_review` rule exists and the
   feature is available. When `pr-merge` invokes this workflow, it passes
   `--skip-copilot-review` and owns the request instead.

The PR API remains scoped to the base repository. Git changes and pushes occur
only in the deterministic PR worktree. A deleted fork, identity mismatch, or
missing push access stops the skill instead of editing the source checkout or
creating a substitute branch.

### Input

- PR URL, or PR number with host-qualified base repository (required)

### Output

- Replies to each review comment
- Whether Copilot Code Review was requested, skipped because it is disabled, or
  skipped because it is unavailable
- Error report if CI still does not pass

## Detailed specification for `pr-merge`

### Workflow

`pr-merge` accepts `pr-merge <PR_URL>`, one or more PR numbers with an optional
host-qualified base repository, or `all [<base-repository>]`. A missing base
repository is resolved from the current checkout's canonical `origin`.

Single-PR mode and batch mode both create or reuse a deterministic worktree
keyed by the PR number. Batch mode retains explicit PR-number order, or
snapshots every open PR with pagination, including drafts, and sorts `all` by
ascending PR number. It never switches the invoking checkout; fork heads use
the same isolated flow when their push remote can be verified.

For each eligible PR, the skill:

1. Re-queries the PR head and active base-branch rules, skipping the optional
   Copilot review when it is unavailable and stopping that PR if the head
   identity changes
2. Creates or reuses the PR-number worktree from the remote with
   `gh pr checkout --worktree`, then verifies its exact head SHA and push
   remote
3. Runs `pr-fix` in `all` mode with `--skip-copilot-review`, then owns one
   Copilot Code Review request and waits for unresolved findings to reach zero
   when the live rules enable it. If Copilot Code Review is unavailable, it
   skips this optional step and continues.
4. Marks the PR ready, skips approval when `reviewDecision` is empty, reuses a
   valid approval, or applies the existing `self approval` label once and waits
   up to three minutes for its automation only when approval blocks the merge.
   If GitHub reports that the PR can merge without approval, it skips the
   label.
5. Waits up to 30 minutes for required CI and mergeability, returning to the
   retry loop for conflicts or failed checks
6. Revalidates the exact head SHA and squash merges with
   `--match-head-commit`, then attempts lease-protected remote head cleanup

Each PR has an independent retry loop capped at 10 iterations and independent
review/approval state. A batch continues after a per-PR failure only while the
source checkout and remaining target worktrees are safe. Dirty files,
unresolved conflicts, or diverged target branches remain isolated to that PR
and are not discarded. A completed batch leaves the source checkout unchanged
and retains the PR worktrees.

> [!NOTE]
> When GitHub reports that review is required, `pr-merge` assumes an automation
> that approves PRs labeled `self approval` and the label itself already exist.
> It does not create either one. If `reviewDecision` is null or empty, or
> GitHub reports that the PR can merge without an approval blocker, the
> automation and label are unnecessary for that workflow.

### Input

- One PR URL
- One or more PR numbers, optionally followed by a host-qualified base repository
- `all`, optionally followed by a host-qualified base repository

### Output

- The merged PR URL for a successful single-PR invocation
- A per-PR merged, failed, or skipped result for a batch
- The failure reason and step when a PR could not be merged
- Whether Copilot Code Review or self approval was skipped as unnecessary
- Remote cleanup warnings and whether the source checkout remained unchanged
