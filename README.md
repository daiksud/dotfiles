# dotfiles

Personal setup for Apple Silicon macOS.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/daiksud/dotfiles/main/bootstrap.sh | bash
```

Requires Git, internet access and administrator permissions. macOS may prompt for Xcode Command Line Tools; GitHub login may require browser authentication.

The bootstrap clones this repository to `~/.dotfiles` and installs Homebrew, Chrome, ChatGPT, Ghostty, Gitify, Moralerspace Neon HW, CLI tools, and global [daiksud/agents](https://github.com/daiksud/agents) instructions for Codex and Copilot. It also configures GitHub CLI extensions and links personal configuration with GNU Stow.

## Update

```sh
cd ~/.dotfiles
git pull --ff-only
./bootstrap.sh
```

Re-running bootstrap also upgrades outdated Homebrew packages with `brew upgrade --no-ask` without a Homebrew confirmation prompt.

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
