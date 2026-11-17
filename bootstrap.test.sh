#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
source_dir="$(cd "$(dirname "$0")" && pwd)"
real_stow="$(command -v stow)"
mkdir -p "$tmp/bin" "$tmp/home" "$tmp/source" "$tmp/Applications"
export HOME="$tmp/home" TRACE="$tmp/trace" SOURCE_DIR="$tmp/source" REAL_STOW="$real_stow"
export PATH="$tmp/bin:$PATH"
unset HOMEBREW_NO_INSTALL_CLEANUP

# Isolate application detection without changing the production installers.
cp -p "$source_dir/bootstrap.sh" "$SOURCE_DIR/bootstrap.sh"
cp -p "$source_dir/update.sh" "$SOURCE_DIR/update.sh"
mkdir -p "$SOURCE_DIR/.git"
for app in homebrew chrome chatgpt ghostty gitify fonts herdr-app; do
  mkdir -p "$SOURCE_DIR/$app"
  cp -p "$source_dir/$app/install.sh" "$SOURCE_DIR/$app/install.sh"
done
cp -R "$source_dir/herdr-app/.config" "$SOURCE_DIR/herdr-app/.config"
cp "$source_dir/herdr-app/.stow-local-ignore" "$SOURCE_DIR/herdr-app/.stow-local-ignore"
cp "$source_dir/homebrew/Brewfile" "$SOURCE_DIR/homebrew/Brewfile"
for app in chrome chatgpt ghostty gitify; do
  sed "s|/Applications/|$tmp/Applications/|g" "$source_dir/$app/install.sh" >"$SOURCE_DIR/$app/install.sh"
done
sed "s|app=/Applications/Herdr.app|app=$tmp/Applications/Herdr.app|" "$source_dir/herdr-app/install.sh" >"$SOURCE_DIR/herdr-app/install.sh"

cat >"$tmp/bin/uname" <<'SH'
#!/usr/bin/env bash
case "$1" in
  -s) echo Darwin ;;
  -m) echo arm64 ;;
  *) exit 1 ;;
esac
SH

cat >"$tmp/bin/brew" <<'SH'
#!/usr/bin/env bash
if [[ "$1" == shellenv ]]; then
  echo 'export PATH="$PATH"'
elif [[ "$1" == list && "$2" == --cask ]]; then
  [[ "${BREW_INSTALLED_CASK:-}" == "$3" ]]
elif [[ "$1 $2" == 'info --cask' ]]; then
  printf '%s\n' '{"casks":[{"version":"0.1.16"}]}'
else
  printf 'brew %s\n' "$*" >>"$TRACE"
  # Model cleanup removing Homebrew's selected curl during install or upgrade.
  if [[ "${MOCK_CURL_CLEANUP:-}" == 1 && ( "$1" == install || "$1" == bundle || "$1" == upgrade ) && "${HOMEBREW_NO_INSTALL_CLEANUP:-}" != 1 ]]; then
    echo 'Error: Failed to get curl path' >&2
    exit 1
  fi
  if [[ "$*" == 'install --cask --adopt font-moralerspace-hw' && "${MOCK_FONT_CONFLICT:-}" == 1 ]]; then
    exit 1
  fi
fi
SH

cat >"$tmp/bin/git" <<'SH'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >>"$TRACE"
if [[ "$1" == -C && ! -d "$2/.git" ]]; then
  exit 128
fi
if [[ "$1" == clone ]]; then
  mkdir -p "$3/homebrew" "$3/chrome" "$3/chatgpt" "$3/ghostty" "$3/gitify" "$3/fonts" "$3/herdr-app" "$3/.git"
  cp "$SOURCE_DIR/bootstrap.sh" "$3/bootstrap.sh"
  cp "$SOURCE_DIR/update.sh" "$3/update.sh"
  cp "$SOURCE_DIR/homebrew/Brewfile" "$3/homebrew/Brewfile"
  for app in homebrew chrome chatgpt ghostty gitify fonts herdr-app; do
    cp -p "$SOURCE_DIR/$app/install.sh" "$3/$app/install.sh"
  done
  cp -R "$SOURCE_DIR/herdr-app/.config" "$3/herdr-app/.config"
  cp "$SOURCE_DIR/herdr-app/.stow-local-ignore" "$3/herdr-app/.stow-local-ignore"
fi
if [[ "$1" == -C && "$3" == pull && -n "${MOCK_UPDATED_UPDATE:-}" && "$2" == "$SOURCE_DIR" ]]; then
  cp "$MOCK_UPDATED_UPDATE" "$2/update.sh.new"
  mv "$2/update.sh.new" "$2/update.sh"
fi
SH

cat >"$tmp/bin/herdr-app" <<'SH'
#!/usr/bin/env bash
printf 'herdr-app %s\n' "$*" >>"$TRACE"
if [[ "$1" == --version ]]; then echo "herdr-app ${MOCK_HERDR_VERSION:-0.1.16}"; exit 0; fi
if [[ "${MOCK_HERDR_APP_FAIL:-}" == "$1" ]]; then exit 1; fi
if [[ "$1" == status ]]; then printf '%s\n' '{"errors":[]}'; fi
SH
cat >"$tmp/bin/open" <<'SH'
#!/usr/bin/env bash
printf 'open %s\n' "$*" >>"$TRACE"
SH

cat >"$tmp/bin/gh" <<'SH'
#!/usr/bin/env bash
if [[ "$1 $2" == 'auth status' ]]; then
  exit 0
fi
if [[ "$1 $2" == 'extension list' ]]; then
  for extension in daiksud/gh-qw daiksud/gh-settings babarot/gh-infra; do
    if [[ -f "$HOME/.mock-gh-${extension##*/}" ]]; then
      printf '%s\n' "$extension"
    fi
  done
  exit 0
fi
printf 'gh %s\n' "$*" >>"$TRACE"
if [[ "$1 $2" == 'extension install' ]]; then
  touch "$HOME/.mock-gh-${3##*/}"
fi
SH

cat >"$tmp/bin/herdr" <<'SH'
#!/usr/bin/env bash
printf 'herdr %s\n' "$*" >>"$TRACE"
case "$1 $2" in
  'plugin list')
    [[ "$3" == --plugin && "$5" == --json ]] || exit 2
    case "$4" in
      dev-shimada.auto-tab-name|daiksud.tab-agent-status|shibayu36.equalize-panes) ;;
      *) exit 2 ;;
    esac
    if [[ -f "$HOME/.mock-herdr-$4" ]]; then
      printf '{"result":{"plugins":[{"plugin_id":"%s","enabled":true}]}}\n' "$4"
    else
      printf '%s\n' '{"result":{"plugins":[]}}'
    fi
    ;;
  'plugin uninstall')
    case "$3" in
      daiksud.tab-agent-status|dev-shimada.auto-tab-name)
        rm -f "$HOME/.mock-herdr-$3"
        ;;
      *) exit 2 ;;
    esac
    ;;
  'plugin install')
    [[ "$3" == shibayu36/herdr-equalize-panes && "$4" == --ref && "$5" == 0c1d940e9af09c632a48a5b179753ef25056ff13 && "$6" == --yes ]] || exit 2
    touch "$HOME/.mock-herdr-shibayu36.equalize-panes"
    ;;
  *) exit 2 ;;
esac
SH

for tool in stow apm; do
  cat >"$tmp/bin/$tool" <<'SH'
#!/usr/bin/env bash
printf '%s %s\n' "${0##*/}" "$*" >>"$TRACE"
if [[ "${0##*/}" == stow && "${USE_REAL_STOW:-}" == 1 ]]; then
  exec "$REAL_STOW" "$@"
fi
if [[ "${0##*/}" == apm && ! -f "$HOME/.apm/apm.yml" ]]; then
  exit 1
fi
SH
done
chmod +x "$tmp/bin/"*
mkdir -p "$HOME/.apm"
touch "$HOME/.apm/apm.yml"
# Simulate both old tab-label plugins for upgrade coverage.
touch "$HOME/.mock-herdr-dev-shimada.auto-tab-name" "$HOME/.mock-herdr-daiksud.tab-agent-status"

# A streamed bootstrap clones once. Other tools are not upgraded by bootstrap.
export MOCK_CURL_CLEANUP=1
(cd "$tmp" && cat "$SOURCE_DIR/bootstrap.sh" | bash)
(cd "$tmp" && cat "$SOURCE_DIR/bootstrap.sh" | bash)
(cd "$tmp" && bash "$SOURCE_DIR/bootstrap.sh")

# An unrelated existing directory is never overwritten by the remote installer.
mkdir -p "$tmp/occupied/.dotfiles"
if (cd "$tmp" && cat "$SOURCE_DIR/bootstrap.sh" | HOME="$tmp/occupied" bash) >/dev/null 2>&1; then
  echo 'FAIL: existing unmanaged checkout was overwritten' >&2
  exit 1
fi

test "$(grep -Fxc "git clone https://github.com/daiksud/dotfiles.git $HOME/.dotfiles" "$TRACE")" -eq 1
! grep -Fq 'pull --ff-only' "$TRACE"
! grep -Fq 'brew upgrade --no-ask' "$TRACE"
! grep -Fq 'gh extension upgrade ' "$TRACE"
! grep -Eq '^apm (update|compile|outdated)' "$TRACE"
test "$(grep -Fc 'brew bundle --no-upgrade --file=' "$TRACE")" -eq 3
test "$(grep -Fxc 'herdr plugin install shibayu36/herdr-equalize-panes --ref 0c1d940e9af09c632a48a5b179753ef25056ff13 --yes' "$TRACE")" -eq 1
test "$(grep -Fxc 'herdr plugin list --plugin shibayu36.equalize-panes --json' "$TRACE")" -eq 3
! grep -Fq 'herdr plugin uninstall' "$TRACE"
! grep -Fq 'herdr plugin link ' "$TRACE"
test -f "$HOME/.mock-herdr-dev-shimada.auto-tab-name"
test -f "$HOME/.mock-herdr-daiksud.tab-agent-status"
! grep -Eq '^apm install( |$)' "$TRACE"
for extension in daiksud/gh-qw daiksud/gh-settings babarot/gh-infra; do
  test "$(grep -Fxc "gh extension install $extension" "$TRACE")" -eq 1
done
grep -F 'stow --no-folding --target=' "$TRACE" | grep -q 'editorconfig fzf git ghostty herdr nvim rumdl sheldon starship zsh'

# Updates pull the repository, upgrade tools and remove obsolete Herdr plugins.
(cd "$tmp" && bash "$SOURCE_DIR/update.sh")
test "$(grep -Fxc "git -C $SOURCE_DIR pull --ff-only" "$TRACE")" -eq 1
test "$(grep -Fxc 'brew upgrade --no-ask' "$TRACE")" -eq 1
test "$(grep -Fxc 'apm update --global --yes' "$TRACE")" -eq 1
test "$(grep -Fxc 'apm compile --global' "$TRACE")" -eq 1
test "$(grep -Fxc 'apm outdated --global' "$TRACE")" -eq 1
for extension in gh-qw gh-settings gh-infra; do
  test "$(grep -Fxc "gh extension upgrade $extension" "$TRACE")" -eq 1
done
test "$(grep -Fxc 'herdr plugin uninstall dev-shimada.auto-tab-name' "$TRACE")" -eq 1
test "$(grep -Fxc 'herdr plugin uninstall daiksud.tab-agent-status' "$TRACE")" -eq 1
test ! -f "$HOME/.mock-herdr-dev-shimada.auto-tab-name"
test ! -f "$HOME/.mock-herdr-daiksud.tab-agent-status"
test "$(grep -Fc 'brew bundle --no-upgrade --file=' "$TRACE")" -eq 4

# The updater must restart from its newly fetched version, not resume stale contents.
cp "$SOURCE_DIR/update.sh" "$tmp/updated-update.sh"
printf '\nprintf "stale update continued\\n" >>"$TRACE"\n' >>"$SOURCE_DIR/update.sh"
(cd "$tmp" && MOCK_UPDATED_UPDATE="$tmp/updated-update.sh" bash "$SOURCE_DIR/update.sh")
test "$(grep -Fxc "git -C $SOURCE_DIR pull --ff-only" "$TRACE")" -eq 2
test "$(grep -Fxc 'brew upgrade --no-ask' "$TRACE")" -eq 2
test "$(grep -Fxc 'apm update --global --yes' "$TRACE")" -eq 2
test "$(grep -Fxc 'apm compile --global' "$TRACE")" -eq 2
test "$(grep -Fxc 'apm outdated --global' "$TRACE")" -eq 2
test "$(grep -Fxc 'herdr plugin uninstall dev-shimada.auto-tab-name' "$TRACE")" -eq 1
test "$(grep -Fxc 'herdr plugin uninstall daiksud.tab-agent-status' "$TRACE")" -eq 1
if grep -Fq 'stale update continued' "$TRACE"; then
  echo 'FAIL: update continued executing stale content after pull' >&2
  exit 1
fi

# A fresh install without global APM configuration still succeeds.
mkdir -p "$tmp/fresh-home"
(cd "$tmp" && HOME="$tmp/fresh-home" bash "$SOURCE_DIR/bootstrap.sh")
test "$(grep -Fxc 'apm update --global --yes' "$TRACE")" -eq 2
test "$(grep -Fxc 'apm compile --global' "$TRACE")" -eq 2
test "$(grep -Fxc 'apm outdated --global' "$TRACE")" -eq 2
test "$(grep -Fxc 'brew upgrade --no-ask' "$TRACE")" -eq 2
test "$(grep -Fc 'brew bundle --no-upgrade --file=' "$TRACE")" -eq 6
test "$(grep -Fxc 'herdr plugin install shibayu36/herdr-equalize-panes --ref 0c1d940e9af09c632a48a5b179753ef25056ff13 --yes' "$TRACE")" -eq 2

# Standalone installers do not reinstall casks already managed by Homebrew.
unset MOCK_CURL_CLEANUP
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=gitify bash gitify/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=chatgpt bash chatgpt/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=google-chrome bash chrome/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=ghostty bash ghostty/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=font-moralerspace-hw bash fonts/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=herdr-app bash herdr-app/install.sh)
test "$(grep -Fxc 'brew upgrade --cask --greedy-auto-updates --no-ask herdr-app' "$TRACE")" -eq 1
if (cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=herdr-app MOCK_HERDR_VERSION=0.1.15 bash herdr-app/install.sh); then
  echo 'FAIL: unsupported Homebrew Herdr App was accepted' >&2
  exit 1
fi
awk '
  /^brew update$/ { refreshed = 1 }
  /^brew (install --cask herdr-app|upgrade --cask --greedy-auto-updates --no-ask herdr-app)$/ {
    if (!refreshed) exit 1
    refreshed = 0
  }
' "$TRACE"

# Standalone installers also preserve manually installed applications and fonts.
mkdir -p "$tmp/Applications/Gitify.app" "$tmp/Applications/ChatGPT.app" "$tmp/Applications/Google Chrome.app" "$tmp/Applications/Ghostty.app" "$tmp/Applications/Herdr.app" "$HOME/Library/Fonts"
mkdir -p "$tmp/Applications/Herdr.app/Contents/MacOS"
cat >"$tmp/Applications/Herdr.app/Contents/MacOS/Herdr" <<'SH'
#!/usr/bin/env bash
if [[ "$1" == --version ]]; then echo "herdr-app ${MOCK_HERDR_VERSION:-0.1.16}"; exit 0; fi
exec herdr-app "$@"
SH
chmod +x "$tmp/Applications/Herdr.app/Contents/MacOS/Herdr"
if (cd "$SOURCE_DIR" && BREW_INSTALLED_CASK= MOCK_HERDR_VERSION=0.1.15 bash herdr-app/install.sh); then
  echo 'FAIL: outdated manual Herdr App was accepted' >&2
  exit 1
fi
touch "$HOME/Library/Fonts/MoralerspaceNeonHW-Regular.ttf" "$HOME/Library/Fonts/MoralerspaceArgonHW-Regular.ttf"
for app in chrome chatgpt ghostty gitify fonts herdr-app; do
  (cd "$SOURCE_DIR" && BREW_INSTALLED_CASK= bash "$app/install.sh")
done
for cask in gitify chatgpt google-chrome ghostty; do
  test "$(grep -Fxc "brew install --cask $cask" "$TRACE")" -eq 6
done
test "$(grep -Fxc 'brew install --cask --adopt font-moralerspace-hw' "$TRACE")" -eq 6

# With just one manually installed font, ask Homebrew to adopt identical
# artifacts; a differing artifact must abort and leave that file intact.
partial_home="$tmp/partial-font-home"
mkdir -p "$partial_home/Library/Fonts"
printf 'manual font\n' >"$partial_home/Library/Fonts/MoralerspaceNeonHW-Regular.ttf"
if (cd "$SOURCE_DIR" && HOME="$partial_home" MOCK_FONT_CONFLICT=1 bash fonts/install.sh); then
  echo 'FAIL: conflicting manual font was accepted' >&2
  exit 1
fi
test "$(cat "$partial_home/Library/Fonts/MoralerspaceNeonHW-Regular.ttf")" = 'manual font'
(cd "$SOURCE_DIR" && HOME="$partial_home" bash fonts/install.sh)
test "$(grep -Fxc 'brew install --cask --adopt font-moralerspace-hw' "$TRACE")" -eq 8

# Real Stow validates replacement, preservation and repeatability in an isolated home.
app_home="$tmp/herdr-app-home"
mkdir -p "$app_home/.config/herdr-app/mods/tabs-no-padding" "$app_home/Applications/Herdr.app"
mkdir -p "$app_home/.config/herdr-app/layouts"
ln -s "$SOURCE_DIR/herdr-app/.config/herdr-app/layouts/main-background.json" "$app_home/.config/herdr-app/layouts/main-background.json"
printf 'old settings\n' >"$app_home/.config/herdr-app/settings.json"
printf 'old mod\n' >"$app_home/.config/herdr-app/mods/tabs-no-padding/main.js"
printf 'retained\n' >"$app_home/.config/herdr-app/shared.json"
if (cd "$SOURCE_DIR" && HOME="$app_home" USE_REAL_STOW=1 MOCK_HERDR_APP_FAIL=check bash herdr-app/install.sh); then
  echo 'FAIL: failed mod check was ignored' >&2
  exit 1
fi
test ! -e "$app_home/.local/state/dotfiles/herdr-app-initialized"
(cd "$SOURCE_DIR" && HOME="$app_home" USE_REAL_STOW=1 bash herdr-app/install.sh)
test -L "$app_home/.config/herdr-app/settings.json"
test -L "$app_home/.config/herdr-app/layouts/daiksud.json"
test ! -L "$app_home/.config/herdr-app/layouts/main-background.json"
test -L "$app_home/.config/herdr-app/mods/tabs-no-padding/main.js"
test "$(cat "$app_home/.config/herdr-app/shared.json")" = retained
test -e "$app_home/.local/state/dotfiles/herdr-app-initialized"
activation_count="$(grep -Fc 'herdr-app do layout.switch' "$TRACE")"
(cd "$SOURCE_DIR" && HOME="$app_home" USE_REAL_STOW=1 bash herdr-app/install.sh)
test "$(grep -Fc 'herdr-app do layout.switch' "$TRACE")" -eq "$activation_count"
test -f "$SOURCE_DIR/herdr-app/.config/herdr-app/settings.json"

# Never traverse a symlinked parent when deleting destinations.
unsafe_home="$tmp/unsafe-home"
mkdir -p "$unsafe_home/.config" "$tmp/external-herdr"
printf 'keep\n' >"$tmp/external-herdr/settings.json"
ln -s "$tmp/external-herdr" "$unsafe_home/.config/herdr-app"
if (cd "$SOURCE_DIR" && HOME="$unsafe_home" USE_REAL_STOW=1 bash herdr-app/install.sh); then
  echo 'FAIL: symlinked configuration directory was accepted' >&2
  exit 1
fi
test "$(cat "$tmp/external-herdr/settings.json")" = keep

# Git is available before Homebrew; cloning precedes package installation.
test "$(head -n 1 "$TRACE")" = "git clone https://github.com/daiksud/dotfiles.git $HOME/.dotfiles"
! grep -Fq 'herdr plugin link ' "$TRACE"
echo 'Bootstrap and updater smoke tests passed'
