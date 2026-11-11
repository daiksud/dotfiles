# dotfiles

Personal setup for Apple Silicon macOS.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/daiksud/dotfiles/main/bootstrap.sh | bash
```

Requires Git, internet access and administrator permissions. macOS may prompt for Xcode Command Line Tools; GitHub login may require browser authentication.

The bootstrap clones this repository to `~/.dotfiles` and installs Homebrew, Chrome, ChatGPT, Ghostty, Gitify, Moralerspace Neon HW, CLI tools (including APM). It does not automatically install [daiksud/agents](https://github.com/daiksud/agents). It also configures GitHub CLI extensions and links personal configuration with GNU Stow.

Herdr uses **workspaces** for navigation and **panes** for splits, with its sidebar visible by default. Tabs are not used as a navigation unit: tab shortcuts are disabled, and the tab bar stays hidden when a workspace has one (internal) tab. Use `Ctrl+Option+H/L` for previous/next workspace. `Ctrl+Option+J` selects the next pane across all workspaces; `Ctrl+Option+K` selects the previous pane. Both wrap around the complete pane list, in workspace, internal tab, then layout order. For example, J cycles `A1 → A2 → B1 → B2 → A1`. `Ctrl+T`, then `Tab` / `Shift+Tab` still cycles within the current tab.

Global pane cycling requires Python 3 and uses `cycle-pane.py`, installed alongside the Herdr config by Stow. The helper uses the session socket supplied by Herdr's shell bindings and serializes repeated invocations before reading the current focus. Its API contract is verified against Herdr 0.9.5; it also traverses any remaining internal tabs in existing workspaces.

Press `Ctrl+T`, then `C` to create a workspace, `Shift+T` to rename it, `Shift+X` to close it, `W` to open the workspace picker, or `1–9` to jump to a workspace. The general Goto picker (`Ctrl+T`, then `G`) remains available. Worktree shortcuts remain disabled. Workspace names are managed manually through Herdr; there is no directory-derived naming or custom Agent status indicator.

Bootstrap unregisters the old `daiksud.tab-agent-status` and `dev-shimada.auto-tab-name` plugins, if installed. Existing workspaces with multiple tabs are **not** automatically converted: move their panes into separate workspaces or close unused tabs before expecting the tab bar to remain hidden.

The revision-pinned [Equalize Panes plugin](https://github.com/shibayu36/herdr-equalize-panes) also automatically balances pane widths when panes are created or closed. Manual resizing persists until the next pane change. Run `herdr plugin action invoke shibayu36.equalize-panes.equalize` inside Herdr to equalize the current pane layout on demand.

To opt in to the global Codex and Copilot instructions, install them explicitly:

```sh
apm install --global daiksud/agents --target codex,copilot
apm compile --global
```

## Update

```sh
~/.dotfiles/bootstrap.sh
```

Bootstrap clones the repository if needed, or fast-forward pulls it with `git pull --ff-only` on repeat runs. It then restarts from the updated script before installing or refreshing tools. It also upgrades Homebrew packages with `brew upgrade --no-ask`. When `~/.apm/apm.yml` exists, it refreshes global APM dependencies, compiles global instructions, and reports remaining outdated APM packages with `apm outdated --global`.

Stow does not overwrite unmanaged files. Resolve any conflicts manually; do not use `--adopt`.

## Layout

- `bootstrap.sh` — setup entry point
- `homebrew/Brewfile` — CLI packages
- `fzf/.config/fzf/options` — shared fzf display options (`FZF_DEFAULT_OPTS_FILE`)
- `homebrew/install.sh`, `chrome/install.sh`, `chatgpt/install.sh`, `ghostty/install.sh`, `gitify/install.sh`, `fonts/install.sh` — application installers
- Application directories — personal configuration linked into `$HOME` with Stow
- `.editorconfig` — repository-specific rules, separate from `editorconfig/.editorconfig`

Use `Ctrl+R` to search Zsh history with `fzf`, or `gg` / `Ctrl+]` to select a `gh qw` repository or worktree. GitHub account mappings and SSH signing keys require personal setup.

## Checks

```sh
bash bootstrap.test.sh
zsh -f zsh/.zsh/gh-account.test.zsh
zsh -f zsh/.zsh/fzf-select-ghqw.test.zsh
zsh -f zsh/.zsh/fzf-select-history.test.zsh
python3 -m unittest discover -s .github/tests -v
```

## Codex automatic approval

The [approval workflow](.github/workflows/approve-codex-review.yml) follows
[gh-settings at `7204c5e`](https://github.com/daiksud/gh-settings/blob/7204c5e466a4640be7c5b10194880dcdb2024d2a/.github/workflows/approve-codex-review.yml)
(after PRs #553 and #554). Its only repository adaptation is the `workflow_run`
name: `CI` here instead of `ci-pr`. Keep the approval logic in sync with that source.

On a Codex Summary comment creation/edit or a completed CI run associated with a
PR, it reads the latest Summary from `chatgpt-codex-connector[bot]`. Approval
requires that bot's PR thumbs-up, **Completed** for both Code Review and Security
Review in the Summary table, and both full `commit_sha` values in its single
`codex-review-state:v1` metadata object matching the current PR HEAD. Missing or
ambiguous evidence withholds approval. The short wait for the thumbs-up is only
polling; elapsed time is not approval evidence. There are no additional file-diff,
CI-result, or elapsed-time approval conditions.

Approval history is paginated and includes both `APPROVED` and `DISMISSED` reviews
by `github-actions[bot]`. Either state for the same PR and HEAD prevents another
automatic approval, including restoration after dismissal. Runs are serialized by
PR, and each approval is pinned to the verified commit. A later push requires both
reviews to identify the new HEAD. A push between verification and submission can
leave an approval on the previous commit; it does not approve the new commit.

The job uses only `pull-requests: write`, with no checkout or execution of PR code.
GitHub CLI and Python 3 must be available on `ubuntu-slim`. The workflow must be
present on the default branch for these events. The Actions setting **Allow GitHub
Actions to create and approve pull requests** must also permit approvals.

Read-only inspection on 2026-11-02 confirmed that the owner enabled that setting.
The checked-in `.github/settings.yml` still has `can_approve_pull_requests: false`;
reconciling that manifest requires a separately authorized settings change, and
applying it as-is could disable automatic approvals again. The live `main` branch
had no protection/rules or required status checks; the existing `CI` workflow runs
`lint` and `test`. Approval does not merge a PR or configure/bypass protection.
No repository settings are changed by this workflow.

For troubleshooting, inspect the workflow step log and **Codex automatic
approval** job summary (`Approved`, `Withheld`, or `Failed`). Local regression
tests mock GitHub API responses and never submit real reviews; run the Python
command above before updating the workflow.
