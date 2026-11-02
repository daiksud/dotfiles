# dotfiles

Personal setup for Apple Silicon macOS.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/daiksud/dotfiles/main/bootstrap.sh | bash
```

Requires Git, internet access and administrator permissions. macOS may prompt for Xcode Command Line Tools; GitHub login may require browser authentication.

The bootstrap clones this repository to `~/.dotfiles` and installs Homebrew, Chrome, ChatGPT, Ghostty, Gitify, Moralerspace Neon HW, CLI tools (including APM). It does not automatically install [daiksud/agents](https://github.com/daiksud/agents). It also configures GitHub CLI extensions and links personal configuration with GNU Stow.

It links the checked-in [Herdr Tab Directory and Agent Status plugin](plugins/herdr-tab-status/README.md) (using macOS system Perl), replacing the old auto-tab-name plugin. Herdr starts with its sidebar hidden and places tabs at the top when there are multiple tabs. Tab names track the focused pane's directory with the most urgent Agent status in the tab: 🔴 blocked, 🟢 done, ⚪ idle/unknown, 🟡 working. Manual tab names are preserved. Use `Ctrl+Option+H/L` for previous/next tab and `Ctrl+Option+J/K` for previous/next pane. The default workspace remains available internally, but workspace and worktree shortcuts are disabled; tabs are the primary navigation unit (create with `Ctrl+T`, then `C`; close with `Ctrl+T`, then `Shift+X`). The general Goto picker (`Ctrl+T`, then `G`) remains available. Tab names update on Herdr events; plain `cd` does not trigger an immediate update.

The revision-pinned [Equalize Panes plugin](https://github.com/shibayu36/herdr-equalize-panes) also automatically balances pane widths when panes are created or closed. Manual resizing persists until the next pane change. Run `herdr plugin action invoke shibayu36.equalize-panes.equalize` inside Herdr to equalize the current tab on demand.

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
/usr/bin/perl plugins/herdr-tab-status/sync.t
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
