#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "${DOTFILES_UPDATE_RESTARTED:-}" != 1 ]]; then
  git -C "$repo_dir" pull --ff-only
  DOTFILES_UPDATE_RESTARTED=1 exec bash "$repo_dir/update.sh"
fi

# Install newly declared dependencies and relink the current configuration.
bash "$repo_dir/bootstrap.sh"

# The bootstrap's Homebrew environment was scoped to its process.
brew_bin="$(command -v brew || printf '%s' /opt/homebrew/bin/brew)"
eval "$("$brew_bin" shellenv)"
brew upgrade --no-ask

# Retire the old tab-label plugins; Herdr's workspace/pane navigation needs neither.
# Keep their saved plugin configuration and state untouched.
for herdr_plugin_id in daiksud.tab-agent-status dev-shimada.auto-tab-name; do
  herdr_plugins="$(herdr plugin list --plugin "$herdr_plugin_id" --json)"
  if jq -e --arg id "$herdr_plugin_id" '.result.plugins | any(.plugin_id == $id)' <<<"$herdr_plugins" >/dev/null; then
    herdr plugin uninstall "$herdr_plugin_id"
  fi
done

if [[ -f "$HOME/.apm/apm.yml" ]]; then
  apm update --global --yes
  apm compile --global
  apm outdated --global
else
  echo "Skipping global APM: $HOME/.apm/apm.yml does not exist."
fi

for extension in gh-qw gh-settings gh-infra; do
  gh extension upgrade "$extension"
done

echo "Update complete."
