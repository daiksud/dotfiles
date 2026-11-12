#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
  echo "This installer requires Apple Silicon macOS." >&2
  exit 1
fi

if [[ -f "${BASH_SOURCE[0]:-}" ]]; then
  repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  repo_dir="$HOME/.dotfiles"
  if [[ -e "$repo_dir" ]]; then
    if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "Existing $repo_dir is not a Git repository." >&2
      exit 1
    fi
  else
    git clone https://github.com/daiksud/dotfiles.git "$repo_dir"
  fi
  exec bash "$repo_dir/bootstrap.sh"
fi

cd "$repo_dir"

# Source Homebrew's shell environment for the other installers.
source ./homebrew/install.sh
./chrome/install.sh
./chatgpt/install.sh
./ghostty/install.sh
./gitify/install.sh
./fonts/install.sh
stow --no-folding --target="$HOME" editorconfig fzf git ghostty herdr nvim rumdl sheldon starship zsh

# Equalize pane widths after splitting or closing panes.
herdr_plugin_id=shibayu36.equalize-panes
herdr_plugins="$(herdr plugin list --plugin "$herdr_plugin_id" --json)"
if ! jq -e --arg id "$herdr_plugin_id" '.result.plugins | any(.plugin_id == $id)' <<<"$herdr_plugins" >/dev/null; then
  herdr plugin install shibayu36/herdr-equalize-panes --ref 0c1d940e9af09c632a48a5b179753ef25056ff13 --yes
fi
gh auth status >/dev/null 2>&1 || gh auth login </dev/tty
for extension in daiksud/gh-qw daiksud/gh-settings babarot/gh-infra; do
  if ! gh extension list | grep -Fq "$extension"; then
    gh extension install "$extension"
  fi
done

echo "Setup complete. Open Ghostty to start your configured environment."
