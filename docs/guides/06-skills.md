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
| `gh-wt`     | Creates and manages CoW-backed git worktrees (list/add/remove/gc) via the gh-wt extension |

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

## Use `gh-wt`

Unlike `pr-create` and `pr-fix`, `gh-wt` is not a hand-authored skill and has no slash command. It was
installed straight from the upstream repository with `gh skill install HikaruEgashira/gh-wt gh-wt`, and
Copilot triggers it automatically whenever your prompt matches its purpose — just describe what you want
in natural language:

```bash
copilot -p "create a worktree for feature-x"
copilot -p "run the tests in a clean worktree without touching my current changes"
copilot -p "open PR #123 side-by-side with main"
```

Phrasing such as "spin up a fresh copy of branch X", "run claude in a clean checkout", or "try this patch
without touching my changes" also triggers the skill, even when the word "worktree" is never said.

### What happens

1. Selects an existing worktree or creates a new one via `gh wt`
2. Runs the command you asked for inside that worktree, or reports its path if you only asked to create
   or list one

### Prerequisite

The skill wraps the `gh wt` extension, so it must be installed once with:

```bash
gh extension install HikaruEgashira/gh-wt
```

In this repository, `install.sh` already installs it for you via `scripts/100-gh-extensions.sh`, so no
manual step is normally required.

See the [gh-wt reference](../reference/gh-wt.md) for the full command list (`gh wt add`, `list`, `remove`,
`gc`, and more).

> [!NOTE]
> Prefer a plain shell shortcut over an AI round-trip? The `gwt` function fzf-selects a worktree and `cd`s
> into it directly, without going through Copilot. See [zsh plugins](../reference/zsh/plugins.md) for details.

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
