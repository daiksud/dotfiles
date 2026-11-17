#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="$HOME/.config/herdr-app"
source_config="$repo_dir/herdr-app/.config/herdr-app"
marker="$HOME/.local/state/dotfiles/herdr-app-initialized"

# Do not follow a directory link when removing a managed destination.
for dir in "$HOME/.config" "$config" "$config/layouts" "$config/themes" "$config/backgrounds" "$config/mods"; do
  if [[ -L "$dir" || ( -e "$dir" && ! -d "$dir" ) ]]; then
    echo "Herdr App: expected a directory, not a link or file: $dir" >&2
    exit 1
  fi
done

files=(settings.json keys.json layouts/daiksud.json themes/tokyo-night-storm.json backgrounds/hololive-en-advent.jpg)
mods=(tabs-no-padding workspace-status-auto-tabs)
for file in "${files[@]}"; do
  if [[ ! -f "$source_config/$file" ]]; then
    echo "Herdr App: missing source file $source_config/$file" >&2
    exit 1
  fi
done
for mod in "${mods[@]}"; do
  if [[ ! -f "$source_config/mods/$mod/main.js" || ! -f "$source_config/mods/$mod/mod.json" ]]; then
    echo "Herdr App: incomplete source mod $mod" >&2
    exit 1
  fi
done

app=/Applications/Herdr.app
if [[ ! -d "$app" && -d "$HOME/Applications/Herdr.app" ]]; then
  app="$HOME/Applications/Herdr.app"
fi
# Refresh the cask metadata even when bootstrap disables automatic updates.
export HOMEBREW_NO_INSTALL_CLEANUP=1
brew update
if brew list --cask herdr-app >/dev/null 2>&1; then
  # Herdr declares auto_updates, so include it explicitly.
  brew upgrade --cask --greedy-auto-updates --no-ask herdr-app
elif [[ ! -d "$app" ]]; then
  brew install --cask herdr-app
else
  # Keep manually installed apps in place, but do not configure an outdated one.
  herdr_app="$app/Contents/MacOS/Herdr"
  app_version="$("$herdr_app" --version | awk '{print $2}')"
  cask_version="$(brew info --cask --json=v2 herdr-app | jq -er '.casks[0].version')"
  if ! jq -en --arg app "$app_version" --arg cask "$cask_version" '
    def version: if test("^[0-9]+(\\.[0-9]+)*$") then split(".") | map(tonumber) else error("invalid version") end;
    ($app | version) >= ($cask | version)
  ' >/dev/null; then
    echo "Herdr App: manually installed $app_version is older than Homebrew's $cask_version; update $app and retry." >&2
    exit 1
  fi
fi

# The custom mods use APIs introduced in 0.1.16, even if the cask is behind.
herdr_app="${herdr_app:-$(command -v herdr-app || true)}"
if [[ -z "$herdr_app" ]]; then
  herdr_app="$app/Contents/MacOS/Herdr"
fi
if [[ ! -x "$herdr_app" ]]; then
  echo "Herdr App: executable not found in PATH or $app" >&2
  exit 1
fi
app_version="$("$herdr_app" --version | awk '{print $2}')"
if ! jq -en --arg version "$app_version" '
  if ($version | test("^[0-9]+(\\.[0-9]+)*$")) then
    ($version | split(".") | map(tonumber)) >= [0, 1, 16]
  else false end
' >/dev/null; then
  echo "Herdr App: version 0.1.16 or later is required; found $app_version." >&2
  exit 1
fi

mkdir -p "$config/layouts" "$config/themes" "$config/backgrounds" "$config/mods"
# Remove the former layout link only when it points into this checkout.
old_layout="$config/layouts/main-background.json"
if [[ -L "$old_layout" ]]; then
  old_target="$(readlink "$old_layout")"
  if [[ "$old_target" != /* ]]; then
    old_target="$config/layouts/$old_target"
  fi
  old_parent="$(cd "$(dirname "$old_target")" 2>/dev/null && pwd -P || true)"
  source_parent="$(cd "$source_config/layouts" && pwd -P)"
  if [[ "$old_parent" == "$source_parent" && "${old_target##*/}" == main-background.json ]]; then
    rm -f "$old_layout"
  fi
fi
for file in "${files[@]}"; do
  target="$config/$file"
  # Preserve correct links; remove the link itself, never its target.
  if [[ -L "$target" && -e "$target" && "$target" -ef "$source_config/$file" ]]; then
    continue
  fi
  if [[ -d "$target" && ! -L "$target" ]]; then
    echo "Herdr App: expected a file at $target" >&2
    exit 1
  fi
  rm -f "$target"
done
for mod in "${mods[@]}"; do
  target="$config/mods/$mod"
  # A matching linked mod already belongs to this checkout. Herdr may add
  # generated files there, so preserve them on subsequent bootstrap runs.
  linked=true
  if [[ -L "$target" || ! -d "$target" ]]; then
    linked=false
  else
    for source in "$source_config/mods/$mod/"*; do
      case "${source##*/}" in gpui-kit.d.ts|jsconfig.json) continue ;; esac
      destination="$target/${source##*/}"
      if [[ ! -L "$destination" || ! -e "$destination" || ! "$destination" -ef "$source" ]]; then
        linked=false
        break
      fi
    done
  fi
  if [[ "$linked" == true ]]; then
    continue
  fi
  if [[ -L "$target" ]]; then
    rm -f "$target"
  elif [[ -e "$target" ]]; then
    rm -rf "$target"
  fi
done
stow --no-folding --dir="$repo_dir" --target="$HOME" herdr-app

if [[ -f "$marker" ]]; then
  exit 0
fi

for mod in "${mods[@]}"; do
  "$herdr_app" check "$config/mods/$mod"
done

if ! "$herdr_app" status >/dev/null 2>&1; then
  open "$app"
  ready=false
  for ((attempt=0; attempt<60; attempt++)); do
    if "$herdr_app" status >/dev/null 2>&1; then
      ready=true
      break
    fi
    sleep 1
  done
  if [[ "$ready" != true ]]; then
    echo "Herdr App: window did not become ready within 60 seconds" >&2
    exit 1
  fi
fi
"$herdr_app" do layout.switch --name daiksud
"$herdr_app" do app.theme --name tokyo-night-storm
status="$("$herdr_app" status)"
if ! jq -e '(.errors // []) | length == 0' <<<"$status" >/dev/null; then
  echo "Herdr App: status reports errors: $status" >&2
  exit 1
fi
mkdir -p "$(dirname "$marker")"
touch "$marker"
