#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
  echo "This installer requires Apple Silicon macOS." >&2
  exit 1
fi

if [[ -f "${BASH_SOURCE[0]:-}" ]]; then
  repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ "${DOTFILES_BOOTSTRAP_UPDATED:-}" != 1 ]]; then
    git -C "$repo_dir" pull --ff-only
    DOTFILES_BOOTSTRAP_UPDATED=1 exec bash "$repo_dir/bootstrap.sh"
  fi
else
  repo_dir="$HOME/.dotfiles"
  if [[ -e "$repo_dir" ]]; then
    git -C "$repo_dir" pull --ff-only
  else
    git clone https://github.com/daiksud/dotfiles.git "$repo_dir"
  fi
  DOTFILES_BOOTSTRAP_UPDATED=1 exec bash "$repo_dir/bootstrap.sh"
fi
cd "$repo_dir"

# Source Homebrew's shell environment for the other installers.
source ./homebrew/install.sh
./chrome/install.sh
./chatgpt/install.sh
./ghostty/install.sh
./gitify/install.sh
./fonts/install.sh
stow --no-folding --target="$HOME" editorconfig git ghostty herdr nvim rumdl sheldon starship zsh

# Install the tab-label plugin once; it keeps tabs named for the focused pane.
herdr_plugin_id=dev-shimada.auto-tab-name
herdr_plugins="$(herdr plugin list --plugin "$herdr_plugin_id" --json)"
if ! jq -e --arg id "$herdr_plugin_id" '.result.plugins | any(.plugin_id == $id)' <<<"$herdr_plugins" >/dev/null; then
  herdr plugin install dev-shimada/herdr-auto-tab-name --yes
fi
apm install --global daiksud/agents --target codex,copilot
apm update --global --yes
apm compile --global
apm outdated --global

gh auth status >/dev/null 2>&1 || gh auth login </dev/tty
gh extension install --force daiksud/gh-qw
gh extension install --force daiksud/gh-settings
gh extension install --force babarot/gh-infra

echo "Setup complete. Open Ghostty to start your configured environment."
