# Using skills

This is a guide for getting started quickly with custom Copilot CLI skills.

## Prerequisites

- dotfiles are already installed (`install.sh` has been run)
- GitHub Copilot CLI is already installed

## Available skills

| Skill       | What it does                                                                              |
| ----------- | ----------------------------------------------------------------------------------------- |
| `pr-create` | Automatically creates a draft PR from the current changes                                 |
| `pr-fix`    | Fixes CI errors, handles reviews, and resolves merge conflicts for the specified PR       |
| `pr-merge`  | Loops `pr-fix` and Copilot Code Review to zero findings, then approves, waits for CI, and squash merges one or more PRs |

## Use `pr-create`

With your changes staged:

```bash
copilot -p "/pr-create"
```

If you want to explain the reason for the change:

```bash
copilot -p "/pr-create Refactor authentication logic, related to #42"
```

In an interactive session, you can also start it with `/pr create` (described later).

### What happens

1. Checks for a corresponding Task (Issue) and suggests creating one if it does not exist
2. Reads the diff and comes up with a commit message
3. Creates and pushes a feature branch
4. Creates a draft PR
5. Sets you as the assignee

## Use `pr-fix`

```bash
copilot -p "/pr-fix PR #42"
```

In an interactive session, you can also start it with `/pr fix` (described later).

### What happens

1. Detects and resolves merge conflicts
2. Identifies CI failures from logs and fixes them (repeating until they pass)
3. Checks review comments and applies reasonable fixes (any comment you reply "対応しない" to is left unchanged, and the reason is recorded in the PR body)
4. Performs a local review before pushing
5. Replies to each review comment with what was addressed and resolves the thread

You can also specify a mode:

```bash
copilot -p "/pr-fix ci #42"        # CI failures only
copilot -p "/pr-fix feedback #42"  # Review comments only
copilot -p "/pr-fix conflicts #42" # Conflicts only
```

## Use `pr-merge`

```bash
copilot -p "/pr-merge 42"
```

Multiple PRs can be given at once, separated by spaces; they are processed one at a time:

```bash
copilot -p "/pr-merge 42 43"
```

In an interactive session, you can also start it with `/pr merge` (described later).

### What happens

For each PR number given:

1. Runs `pr-fix` and requests a review from Copilot Code Review, repeating until there are no unresolved findings (up to 10 attempts)
2. Takes the PR out of Draft and applies the `self approval` label
3. Waits for the repository's existing self-approval automation to approve the PR (up to 3 minutes)
4. Waits for CI to go green, going back to step 1 if a merge conflict or a CI failure shows up
5. Squash merges the PR once everything is green

If a PR cannot be brought to a mergeable state, it is skipped (with the reason recorded) so the rest of the batch keeps going, and a summary is reported at the end.

> [!IMPORTANT]
> `pr-merge` waits for an existing automation that approves PRs labeled `self approval` — it does not create that automation. It also expects the `self approval` label to already exist in the repository.

## Integration with `/pr create`, `/pr fix`, and `/pr merge`

`install.sh` creates a symbolic link from `dotfiles/copilot-instructions.md` to `~/.copilot/copilot-instructions.md`.
This file contains the following instructions and is always loaded in interactive sessions:

- When `/pr create` is invoked → use the `pr-create` skill
- When `/pr fix` is invoked → use the `pr-fix` skill
- When `/pr merge` is invoked → use the `pr-merge` skill

As a result, even when you use the built-in `/pr` subcommand, it behaves according to the procedure defined in the skills.

> [!NOTE]
> This integration works through Copilot instruction loading and is not a completely deterministic binding. If you want to ensure the skill is used, invoke it directly with `/pr-create`, `/pr-fix`, or `/pr-merge`.

## Alias setup (recommended)

Add the following to `.zshrc` or `.bashrc`:

```bash
alias pr-create='f() { copilot --model ${COPILOT_MODEL:-claude-sonnet-4.6} -p "/pr-create skill $*"; }; f'
alias pr-fix='f() { copilot --model ${COPILOT_MODEL:-claude-sonnet-4.6} -p "/pr-fix skill $*"; }; f'
alias pr-merge='f() { copilot --model ${COPILOT_MODEL:-claude-sonnet-4.6} -p "/pr-merge skill $*"; }; f'
```

Usage:

```bash
pr-create
pr-fix PR #42
pr-merge 42
```
