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

# Re-link on every run to refresh Herdr's registered plugin manifest. Simply
# editing a linked manifest does not update the already registered commands.
# Do this before removing the previous renamer so failures keep it available.
herdr plugin link "$repo_dir/plugins/herdr-tab-status"

# Do not keep two tab-name writers active. Herdr retains the former plugin's
# state after uninstall, allowing the replacement to adopt its owned labels.
herdr_plugin_id=dev-shimada.auto-tab-name
herdr_plugins="$(herdr plugin list --plugin "$herdr_plugin_id" --json)"
if jq -e --arg id "$herdr_plugin_id" '.result.plugins | any(.plugin_id == $id)' <<<"$herdr_plugins" >/dev/null; then
  herdr plugin uninstall "$herdr_plugin_id"
fi

# Equalize pane widths after splitting or closing panes.
herdr_plugin_id=shibayu36.equalize-panes
herdr_plugins="$(herdr plugin list --plugin "$herdr_plugin_id" --json)"
if ! jq -e --arg id "$herdr_plugin_id" '.result.plugins | any(.plugin_id == $id)' <<<"$herdr_plugins" >/dev/null; then
  herdr plugin install shibayu36/herdr-equalize-panes --ref 0c1d940e9af09c632a48a5b179753ef25056ff13 --yes
fi
if [[ -f "$HOME/.apm/apm.yml" ]]; then
  apm update --global --yes
  apm compile --global
  apm outdated --global
else
  echo "Skipping global APM: $HOME/.apm/apm.yml does not exist."
fi

gh auth status >/dev/null 2>&1 || gh auth login </dev/tty
gh extension install --force daiksud/gh-qw
gh extension install --force daiksud/gh-settings
gh extension install --force babarot/gh-infra

echo "Setup complete. Open Ghostty to start your configured environment."
