---
name: herdr-subagents
description: Deploy one or more coding subagents into Herdr panes and tabs when the invoking agent is already in a Herdr-managed pane. Use for one or more subagent tasks that need visible, independently controllable agents; preserve the caller's focus, collect results, and clean up successful work.
---

# herdr-subagents

## Overview

Use Herdr to run each requested subagent in its own terminal pane. This makes
the agents independently visible and controllable while leaving the invoking
agent in its current pane. Use this skill for every subagent deployment when
the invoking agent is already running in a Herdr-managed pane.

## Preconditions

1. Confirm that the caller is in Herdr:

   ```bash
   test "${HERDR_ENV:-}" = 1
   command -v herdr
   ```

   If either check fails, do not inspect or control Herdr. Use the host's
   native subagent mechanism instead and report why the Herdr fallback was
   necessary.
2. Confirm the caller context and that Herdr can answer a read-only request:

   ```bash
   herdr pane current --current
   herdr agent get "$HERDR_PANE_ID"
   ```

   If either command fails, use the same fallback. Do not run bare `herdr`,
   because it opens or attaches to the interactive UI.
3. Treat the installed CLI as the syntax authority. Before relying on a
   command not covered here, inspect it with `herdr --help` and the applicable
   command group, such as `herdr pane`, `herdr tab`, or `herdr agent`.
4. Determine each requested agent kind. A user-specified kind takes priority;
   otherwise use the invoking agent's recognized kind. For example, an
   invoking Copilot, Codex, or Claude Code agent uses `copilot`, `codex`, or
   `claude`. Confirm supported kinds with `herdr agent`. Do not guess when the
   caller cannot be identified or no matching kind is available.
5. When a requested kind is `copilot`, preserve the parent's Copilot user
   context with `COPILOT_GITHUB_TOKEN`. Require that it is nonempty in the
   parent and that Herdr launches Zsh, without printing the token:

   ```bash
   test -n "${COPILOT_GITHUB_TOKEN:-}"
   test "$(basename "${SHELL:-}")" = zsh
   ```

   Create one private bootstrap directory for the fan-out. Store the token in
   a mode-600 file without putting its value in command arguments, and make a
   temporary `.zshenv` load it before restoring the normal `ZDOTDIR`:

   ```bash
   parent_zdotdir="${ZDOTDIR:-$HOME}"
   bootstrap_dir="$(mktemp -d "${TMPDIR:-/tmp}/herdr-copilot.XXXXXX")"
   chmod 700 "$bootstrap_dir"
   (
     umask 077
     printf '%s' "$COPILOT_GITHUB_TOKEN" >"$bootstrap_dir/token"
     printf '%s\n' \
       'typeset _herdr_bootstrap_dir="$ZDOTDIR"' \
       'typeset _herdr_parent_zdotdir="${HERDR_PARENT_ZDOTDIR:-$HOME}"' \
       'if [[ -r "$_herdr_bootstrap_dir/token" ]]; then' \
       '  export COPILOT_GITHUB_TOKEN="$(<"$_herdr_bootstrap_dir/token")"' \
       'fi' \
       'export ZDOTDIR="$_herdr_parent_zdotdir"' \
       'unset HERDR_PARENT_ZDOTDIR' \
       'if [[ -r "$ZDOTDIR/.zshenv" ]]; then' \
       '  source "$ZDOTDIR/.zshenv"' \
       'fi' \
       'unset _herdr_bootstrap_dir _herdr_parent_zdotdir' \
       >"$bootstrap_dir/.zshenv"
   )
   ```

   For every `herdr pane split` or `herdr tab create` that creates a Copilot
   target, add `--env "ZDOTDIR=$bootstrap_dir"` and
   `--env "HERDR_PARENT_ZDOTDIR=$parent_zdotdir"` immediately before
   `--no-focus`. Only non-secret directory paths appear in Herdr's command
   arguments. The bootstrap explicitly sources the parent's original
   `.zshenv`, then later Zsh startup files load from that original directory.
   Do not add these variables to non-Copilot or unused panes.
   - If the parent token is empty, the shell is not Zsh, or the private files
     cannot be created with the required permissions, do not start a Copilot
     child. Remove any bootstrap files already created, use the native
     fallback, and report why.
   - Do not run `copilot login`, `copilot logout`, or the interactive `/user`
     command for a child agent.
   - Never print, place in a prompt, or replace the token. Do not enable shell
     tracing while preparing or using the bootstrap.
   - Do not pass a different `--host`, `COPILOT_HOME`, or other account
     selection setting to the child.

## Prepare the work

1. Count the subagents to start as `N`.
2. Give every subagent a self-contained prompt. Include the absolute checkout
   path, its assigned scope, expected output, relevant constraints, and whether
   it may edit files. Explicitly forbid commits, pushes, destructive commands,
   and out-of-scope edits unless the user requested them.
3. Allow concurrent writes only when the agents have non-overlapping,
   explicitly assigned file scopes. Read-only tasks may overlap. If write
   scopes cannot be separated safely, do not fan them out; combine the work or
   run it sequentially instead.
4. Do not create a Git worktree solely for this workflow. Use the invoking
   checkout unless the user explicitly requests another checkout.
5. Choose a unique lowercase name for every agent that matches
   `[a-z][a-z0-9_-]{0,31}`. Check `herdr agent list` first, and retry with a
   different suffix if `herdr agent start` reports a collision.

## Create the layout

Record every tab and pane ID from Herdr's JSON responses. Never infer IDs from
the UI, sidebar order, or the examples below. Use `--no-focus` for every
creation so the user's focus stays in the caller pane.

### One or two subagents

Keep the caller in the left pane of the current tab.

1. Create the right pane and record its returned pane ID:

   ```bash
   herdr pane split --current --direction right --cwd "$PWD" \
     --no-focus
   ```

2. For `N=1`, start the agent in that returned right pane.
3. For `N=2`, split that returned right pane down and record the new bottom
   pane ID:

   ```bash
   herdr pane split --pane <right-pane-id> --direction down \
     --cwd "$PWD" --no-focus
   ```

   Start one agent in the existing right pane and one in the new bottom pane.
   Do not start an agent in the caller's left pane.

### Three or four subagents

Create one new tab in the caller's workspace. The tab has a 2x2 grid; assign
agents in top-left, top-right, bottom-left, bottom-right order. For `N=3`,
leave the final bottom-right pane as a shell.

1. Create the tab, then record the returned tab ID and root pane ID:

   ```bash
   herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$PWD" \
     --no-focus
   ```

2. Split the root right, then split both top panes down:

   ```bash
   herdr pane split --pane <root-pane-id> --direction right \
     --cwd "$PWD" --no-focus
   herdr pane split --pane <root-pane-id> --direction down \
     --cwd "$PWD" --no-focus
   herdr pane split --pane <right-pane-id> --direction down \
     --cwd "$PWD" --no-focus
   ```

   The first split returns the top-right pane. The second and third return the
   bottom-left and bottom-right panes respectively.

### Five or more subagents

Partition the agents into groups of four. Create `ceil(N / 4)` new tabs and
build the 2x2 layout above in each tab. Assign the last group in the same
top-left, top-right, bottom-left, bottom-right order; any unused quadrant
remains a shell. Do not alter the caller's current tab for this case.

## Start and dispatch agents

1. Start one agent in each assigned fresh shell pane:

   ```bash
   herdr agent start <unique-name> --kind <kind> --pane <pane-id>
   ```

   `agent start` returns only after Herdr recognizes the expected agent as
   ready. Never start an agent in a pane that is not one of the panes created
   for this run.
   For a Copilot pane, first confirm only the presence of the forwarded token;
   do not read or print its value:

   ```bash
   herdr pane run <pane-id> \
     'test -n "${COPILOT_GITHUB_TOKEN:-}" && printf "%s%s\n" copilot- token-ready'
   herdr pane wait-output <pane-id> \
     --regex '(?m)^copilot-token-ready$' --timeout 30000
   ```

   Require an output line exactly equal to `copilot-token-ready`; the command
   itself deliberately does not contain that complete marker. If the marker is
   absent, leave the pane open, do not start the agent, and use the native
   fallback.
   After every Copilot target pane reports the marker, remove the credential
   bootstrap before starting any agent:

   ```bash
   rm "$bootstrap_dir/token" "$bootstrap_dir/.zshenv"
   rmdir "$bootstrap_dir"
   unset bootstrap_dir parent_zdotdir
   ```

   The token remains in each initialized shell environment, but no temporary
   credential file remains. On any failure, remove the files with the same
   exact-path commands before falling back.
2. Submit all prompts before waiting for any one result. Start each
   `herdr agent prompt <name> <prompt> --wait --timeout <milliseconds>` command
   in the background, record its PID and agent name, then wait for all recorded
   PIDs. Waiting immediately after each prompt serializes the work and defeats
   the fan-out.
3. Treat a failed prompt command, a `blocked` state, or an unrecognized agent
   state as unsuccessful. A settled `idle` or `done` state confirms only the
   agent lifecycle; it does not prove that the agent produced a usable answer.
   Inspect it before deciding how to proceed:

   ```bash
   herdr agent get <name>
   herdr agent read <name> --source recent-unwrapped --lines 120
   ```

   Do not approve destructive actions or answer agent questions automatically.
   Surface them to the user when needed.

## Collect results and clean up

1. After every dispatched prompt settles successfully, read each final result:

   ```bash
   herdr agent read <name> --source recent-unwrapped --lines 120
   ```

   If an alternate screen prevents recovery of the complete result, ask that
   agent to write its response to a Markdown file in a temporary directory and
   reply only with the file path. Read that file directly as a fallback.
   Treat a quota, authentication, service, or other agent error -- or a missing
   required result -- as unsuccessful even when Herdr reports the agent as
   `idle` or `done`.
2. Only after every result is captured successfully, close resources created
   by this run:
   - For `N=1` or `N=2`, close only the created panes with `herdr pane close`,
     in reverse creation order. Never close the caller pane.
   - For `N>=3`, close only the tabs created by this run with
     `herdr tab close <tab-id>`. This also removes their spare shell panes.
3. If any agent fails, times out, is blocked, or cannot be read, leave every
   created pane and tab open. Report the agent names, pane IDs, tab IDs, and
   current states so the user can inspect or resume the work.

## Output

Report the assigned agent names and scopes, their collected results, whether
the created layout was cleaned up, and any fallback or unresolved state. State
plainly when work was not parallelized because write scopes overlapped.

## Constraints

- Use `--current`, an explicit pane ID, an explicit tab ID, or a unique agent
  name. Never rely on the UI-focused pane.
- Preserve the caller's focus with `--no-focus` unless the user explicitly
  asks to switch context.
- Never close, move, resize, or otherwise alter a pane or tab that this run
  did not create.
- Never stop the Herdr server or kill the main Herdr process.
- Do not substitute a product-specific Herdr integration for this portable
  procedure. The host's native subagent mechanism is the only fallback when
  Herdr cannot be used safely.
