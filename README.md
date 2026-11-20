# dotfiles

Personal setup for Apple Silicon macOS.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/daiksud/dotfiles/main/bootstrap.sh | bash
```

Requires Git, internet access and administrator permissions. macOS may prompt for Xcode Command Line Tools; GitHub login may require browser authentication.

The bootstrap clones this repository to `~/.dotfiles` when missing and installs Homebrew, Chrome, ChatGPT, Ghostty, Gitify, Herdr App, Moralerspace HW fonts, and CLI tools (including APM). It does not automatically install [daiksud/agents](https://github.com/daiksud/agents). It also configures GitHub CLI extensions and links personal configuration with GNU Stow.

Bootstrap and update disable Homebrew's automatic install cleanup to prevent it from removing curl while an installation is using it. Run `brew cleanup` separately when desired.

### Herdr App

Herdr App is separate from the Herdr terminal application described below. Bootstrap refreshes Homebrew metadata and installs or upgrades the Homebrew-managed app before linking the exported `daiksud` layout, Tokyo Night Storm theme, background, keys, settings and custom mods into `~/.config/herdr-app`. It preserves a manually installed app in `/Applications` or `~/Applications` and asks for an update if it is older than the Homebrew version.

The custom mods require Herdr App 0.1.16 or later. If Homebrew has not yet published a new enough cask, update the app and rerun setup when a compatible version is available.

The `daiksud` layout and the `tabs-no-padding` and `workspace-status-auto-tabs` mods are modified from [Herdr App 0.1.16](https://github.com/herdrdev/herdr-app/tree/v0.1.16), licensed under [Apache License 2.0](herdr-app/LICENSE).

**The installer replaces existing files at those specific configuration paths, including both custom mod directories, without a backup.** Other Herdr App files, including session and window state, are left in place. Before the first run, save any settings you want to retain. Herdr App uses `Moralerspace Argon HW`; the font installer checks for both Argon and Neon.

On first setup, bootstrap checks both mods, starts Herdr App if necessary, and selects the custom layout and theme. Subsequent runs leave the selected layout and theme alone. To select them manually while the app is running:

```sh
herdr-app do layout.switch --name daiksud
herdr-app do app.theme --name tokyo-night-storm
herdr-app status
```

To repeat first-run activation, remove `~/.local/state/dotfiles/herdr-app-initialized` and rerun bootstrap. The exported layout and mods were built with Herdr App 0.1.16; after app updates, check the display and keyboard shortcuts. Editing `keys.json` prevents Herdr from automatically adding new default shortcuts. The tab bar hides when the active space has one tab and reappears with multiple tabs; while hidden, its buttons are unavailable.

The `daiksud` layout keeps at least one terminal pane open across all spaces. Once the saved layouts have loaded, it opens a shell if no terminal pane remains, including at startup and after the last shell exits or its pane, tab, or space is closed. The shell opens in a new tab in the active space, or in a new space when none remains. It waits while the target machine is unavailable; mod-only panes do not count as terminals.

The status bar shows the app computer's local date and time on the right, updating every second in the format `Fri Nov 20 18:16:32` with English weekday and month names and a 24-hour clock.

### Herdr TUI

Herdr uses **workspaces** for navigation and **panes** for splits, with its sidebar visible by default. Tabs are not used as a navigation unit: tab shortcuts are disabled, and the tab bar stays hidden when a workspace has one (internal) tab. Use `Ctrl+Option+H/L` for previous/next workspace. `Ctrl+Option+J` selects the next pane across all workspaces; `Ctrl+Option+K` selects the previous pane. Both wrap around the complete pane list, in workspace, internal tab, then layout order. For example, J cycles `A1 → A2 → B1 → B2 → A1`. `Ctrl+T`, then `Tab` / `Shift+Tab` still cycles within the current tab.

Global pane cycling requires Python 3 and uses `cycle-pane.py`, installed alongside the Herdr config by Stow. The helper uses the session socket supplied by Herdr's shell bindings and serializes repeated invocations before reading the current focus. Its API contract is verified against Herdr 0.9.5; it also traverses any remaining internal tabs in existing workspaces.

Press `Ctrl+T`, then `C` to create a workspace, `Shift+T` to rename it, `Shift+X` to close it, `W` to open the workspace picker, or `1–9` to jump to a workspace. The general Goto picker (`Ctrl+T`, then `G`) remains available. Worktree shortcuts remain disabled. Workspace names are managed manually through Herdr; there is no directory-derived naming or custom Agent status indicator.

The updater unregisters the old `daiksud.tab-agent-status` and `dev-shimada.auto-tab-name` plugins, if installed. Existing workspaces with multiple tabs are **not** automatically converted: move their panes into separate workspaces or close unused tabs before expecting the tab bar to remain hidden.

The revision-pinned [Equalize Panes plugin](https://github.com/shibayu36/herdr-equalize-panes) also automatically balances pane widths when panes are created or closed. Manual resizing persists until the next pane change. Run `herdr plugin action invoke shibayu36.equalize-panes.equalize` inside Herdr to equalize the current pane layout on demand.

To opt in to the global Codex and Copilot instructions, install them explicitly:

```sh
apm install --global daiksud/agents --target codex,copilot
apm compile --global
```

## Update

```sh
~/.dotfiles/update.sh
```

Bootstrap installs missing components and upgrades Herdr App. Re-running it does not pull repository changes or explicitly upgrade other installed tools.

The updater fast-forward pulls the repository with `git pull --ff-only` and restarts from the updated script. It reruns setup to install newly declared dependencies and refresh Stow links, then upgrades Homebrew packages and the three configured GitHub CLI extensions. When `~/.apm/apm.yml` exists, it refreshes global APM dependencies, compiles global instructions, and reports remaining outdated APM packages with `apm outdated --global`.

Apart from the Herdr App paths described above, Stow does not overwrite unmanaged files. Resolve any conflicts manually; do not use `--adopt`.

## Layout

- `bootstrap.sh` — setup entry point
- `update.sh` — update repository and installed tools
- `homebrew/Brewfile` — CLI packages
- `fzf/.config/fzf/options` — shared fzf display options (`FZF_DEFAULT_OPTS_FILE`)
- `homebrew/install.sh`, `chrome/install.sh`, `chatgpt/install.sh`, `ghostty/install.sh`, `gitify/install.sh`, `herdr-app/install.sh`, `fonts/install.sh` — application installers
- `herdr-app/.config/herdr-app` — Herdr App settings and custom layout
- Application directories — personal configuration linked into `$HOME` with Stow
- `.editorconfig` — repository-specific rules, separate from `editorconfig/.editorconfig`

Use `Ctrl+R` to search Zsh history with `fzf`, or `gg` / `Ctrl+]` to select a `gh qw` repository or worktree. GitHub account mappings and SSH signing keys require personal setup.

Open a new Zsh session after bootstrap to load the official [gh-qw shell integration](https://github.com/daiksud/gh-qw#install). Use `gh qw add --cd /path/to/repository` to register and enter an existing checkout, or `gh qw add --worktree --cd -b feature/example main` from a registered repository to create and enter a worktree. Other `gh` commands continue to use the normal GitHub CLI.

## Checks

```sh
bash bootstrap.test.sh
zsh -f zsh/.zsh/gh-account.test.zsh
zsh -f zsh/.zsh/gh-qw-shell.test.zsh
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
