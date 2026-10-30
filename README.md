# dotfiles

Personal setup for Apple Silicon macOS.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/daiksud/dotfiles/main/bootstrap.sh | bash
```

Requires Git, internet access and administrator permissions. macOS may prompt for Xcode Command Line Tools; GitHub login may require browser authentication.

The bootstrap clones this repository to `~/.dotfiles` and installs Homebrew, Chrome, ChatGPT, Ghostty, Gitify, Moralerspace Neon HW, CLI tools, and global [daiksud/agents](https://github.com/daiksud/agents) instructions for Codex and Copilot. It also configures GitHub CLI extensions and links personal configuration with GNU Stow.

It links the checked-in [Herdr Tab Directory and Agent Status plugin](plugins/herdr-tab-status/README.md) (using Node.js), replacing the old auto-tab-name plugin. Herdr starts with its sidebar hidden and places tabs at the top when there are multiple tabs. Tab names track the focused pane's directory with the most urgent Agent status in the tab: 🔴 blocked, 🟢 done, ⚪ idle/unknown, 🟡 working. Manual tab names are preserved. Use `Ctrl+Option+H/L` for previous/next tab and `Ctrl+Option+J/K` for previous/next pane. The default workspace remains available internally, but workspace and worktree shortcuts are disabled; tabs are the primary navigation unit (create with `Ctrl+T`, then `C`; close with `Ctrl+T`, then `Shift+X`). The general Goto picker (`Ctrl+T`, then `G`) remains available. Tab names update on Herdr events; plain `cd` does not trigger an immediate update.

The revision-pinned [Equalize Panes plugin](https://github.com/shibayu36/herdr-equalize-panes) also automatically balances pane widths when panes are created or closed. Manual resizing persists until the next pane change. Run `herdr plugin action invoke shibayu36.equalize-panes.equalize` inside Herdr to equalize the current tab on demand.

## Update

```sh
~/.dotfiles/bootstrap.sh
```

Bootstrap clones the repository if needed, or fast-forward pulls it with `git pull --ff-only` on repeat runs. It then restarts from the updated script before installing or refreshing tools. It also upgrades Homebrew packages with `brew upgrade --no-ask`, refreshes global APM dependencies, compiles global instructions, and reports remaining outdated APM packages with `apm outdated --global`.

Stow does not overwrite unmanaged files. Resolve any conflicts manually; do not use `--adopt`.

## Layout

- `bootstrap.sh` — setup entry point
- `homebrew/Brewfile` — CLI packages
- `homebrew/install.sh`, `chrome/install.sh`, `chatgpt/install.sh`, `ghostty/install.sh`, `gitify/install.sh`, `fonts/install.sh` — application installers
- Application directories — personal configuration linked into `$HOME` with Stow
- `.editorconfig` — repository-specific rules, separate from `editorconfig/.editorconfig`

Use `Ctrl+R` to search Zsh history with `fzf`, or `gg` / `Ctrl+]` to select a `gh qw` repository or worktree. GitHub account mappings and SSH signing keys require personal setup.

## Checks

```sh
bash bootstrap.test.sh
node --test plugins/herdr-tab-status/sync.test.mjs
zsh -f zsh/.zsh/gh-account.test.zsh
zsh -f zsh/.zsh/repository-select.test.zsh
zsh -f zsh/.zsh/fzf-select-history.test.zsh
```
