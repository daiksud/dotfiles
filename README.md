# dotfiles

Personal setup for Apple Silicon macOS.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/daiksud/dotfiles/main/bootstrap.sh | bash
```

Requires Git, internet access and administrator permissions. macOS may prompt for Xcode Command Line Tools; GitHub login may require browser authentication.

The bootstrap clones this repository to `~/.dotfiles` and installs Homebrew, Chrome, ChatGPT, Ghostty, Gitify, Moralerspace Neon HW, CLI tools, and global [daiksud/agents](https://github.com/daiksud/agents) instructions for Codex and Copilot. It also configures GitHub CLI extensions and links personal configuration with GNU Stow.

It also installs a revision-pinned [Herdr auto tab name plugin](https://github.com/dev-shimada/herdr-auto-tab-name) (with Node.js) on the first run. Herdr starts with its sidebar hidden, places tabs at the top when there are multiple tabs, and names tabs after the focused pane's working directory. Use `Ctrl+Option+H/L` for previous/next tab and `Ctrl+Option+J/K` for previous/next pane. The default workspace remains available internally, but workspace/worktree and Goto keyboard shortcuts are disabled; tabs are the primary navigation unit (create with `Ctrl+T`, then `C`; close with `Ctrl+T`, then `Shift+X`). Tab names refresh on Herdr events (such as switching panes); plain `cd` does not trigger an immediate update.

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
zsh -f zsh/.zsh/gh-account.test.zsh
zsh -f zsh/.zsh/repository-select.test.zsh
zsh -f zsh/.zsh/fzf-select-history.test.zsh
```
