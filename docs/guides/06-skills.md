# Using skills

This is a guide for getting started quickly with custom Copilot CLI skills.

## Prerequisites

- dotfiles are already installed (`install.sh` has been run)
- GitHub Copilot CLI is already installed

## Available skills

| Skill       | What it does                                                      |
| ----------- | ----------------------------------------------------------------- |
| `pr-create` | Automatically creates a draft PR from the current changes         |
| `pr-fix`    | Fixes CI errors, handles reviews, and resolves merge conflicts for the specified PR |

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
3. Checks review comments and applies reasonable fixes
4. Performs a local review before pushing
5. Replies to each review comment with what was addressed and resolves the thread

You can also specify a mode:

```bash
copilot -p "/pr-fix ci #42"        # CI failures only
copilot -p "/pr-fix feedback #42"  # Review comments only
copilot -p "/pr-fix conflicts #42" # Conflicts only
```

## Integration with `/pr create` and `/pr fix`

`install.sh` creates a symbolic link from `dotfiles/copilot-instructions.md` to `~/.copilot/copilot-instructions.md`.
This file contains the following instructions and is always loaded in interactive sessions:

- When `/pr create` is invoked → use the `pr-create` skill
- When `/pr fix` is invoked → use the `pr-fix` skill

As a result, even when you use the built-in `/pr` subcommand, it behaves according to the procedure defined in the skills.

> [!NOTE]
> This integration works through Copilot instruction loading and is not a completely deterministic binding. If you want to ensure the skill is used, invoke it directly with `/pr-create` or `/pr-fix`.

## Alias setup (recommended)

Add the following to `.zshrc` or `.bashrc`:

```bash
alias pr-create='f() { copilot --model ${COPILOT_MODEL:-claude-sonnet-4.6} -p "/pr-create skill $*"; }; f'
alias pr-fix='f() { copilot --model ${COPILOT_MODEL:-claude-sonnet-4.6} -p "/pr-fix skill $*"; }; f'
```

Usage:

```bash
pr-create
pr-fix PR #42
```
