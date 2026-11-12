#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
source_dir="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$tmp/bin" "$tmp/home" "$tmp/source" "$tmp/Applications"
export HOME="$tmp/home" TRACE="$tmp/trace" SOURCE_DIR="$tmp/source"
export PATH="$tmp/bin:$PATH"

# Isolate application detection without changing the production installers.
cp -p "$source_dir/bootstrap.sh" "$SOURCE_DIR/bootstrap.sh"
cp -p "$source_dir/update.sh" "$SOURCE_DIR/update.sh"
mkdir -p "$SOURCE_DIR/.git"
for app in homebrew chrome chatgpt ghostty gitify fonts; do
  mkdir -p "$SOURCE_DIR/$app"
  cp -p "$source_dir/$app/install.sh" "$SOURCE_DIR/$app/install.sh"
done
cp "$source_dir/homebrew/Brewfile" "$SOURCE_DIR/homebrew/Brewfile"
for app in chrome chatgpt ghostty gitify; do
  sed "s|/Applications/|$tmp/Applications/|g" "$source_dir/$app/install.sh" >"$SOURCE_DIR/$app/install.sh"
done

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
else
  printf 'brew %s\n' "$*" >>"$TRACE"
fi
SH

cat >"$tmp/bin/git" <<'SH'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >>"$TRACE"
if [[ "$1" == -C && ! -d "$2/.git" ]]; then
  exit 128
fi
if [[ "$1" == clone ]]; then
  mkdir -p "$3/homebrew" "$3/chrome" "$3/chatgpt" "$3/ghostty" "$3/gitify" "$3/fonts" "$3/.git"
  cp "$SOURCE_DIR/bootstrap.sh" "$3/bootstrap.sh"
  cp "$SOURCE_DIR/update.sh" "$3/update.sh"
  cp "$SOURCE_DIR/homebrew/Brewfile" "$3/homebrew/Brewfile"
  for app in homebrew chrome chatgpt ghostty gitify fonts; do
    cp -p "$SOURCE_DIR/$app/install.sh" "$3/$app/install.sh"
  done
fi
if [[ "$1" == -C && "$3" == pull && -n "${MOCK_UPDATED_UPDATE:-}" && "$2" == "$SOURCE_DIR" ]]; then
  cp "$MOCK_UPDATED_UPDATE" "$2/update.sh.new"
  mv "$2/update.sh.new" "$2/update.sh"
fi
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

# A streamed bootstrap clones once. Neither repeat runs nor local runs upgrade tools.
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
! grep -Fq 'brew upgrade ' "$TRACE"
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
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=gitify bash gitify/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=chatgpt bash chatgpt/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=google-chrome bash chrome/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=ghostty bash ghostty/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=font-moralerspace-hw bash fonts/install.sh)

# Standalone installers also preserve manually installed applications and fonts.
mkdir -p "$tmp/Applications/Gitify.app" "$tmp/Applications/ChatGPT.app" "$tmp/Applications/Google Chrome.app" "$tmp/Applications/Ghostty.app" "$HOME/Library/Fonts"
touch "$HOME/Library/Fonts/MoralerspaceNeonHW-Regular.ttf"
for app in chrome chatgpt ghostty gitify fonts; do
  (cd "$SOURCE_DIR" && BREW_INSTALLED_CASK= bash "$app/install.sh")
done
for cask in gitify chatgpt google-chrome ghostty font-moralerspace-hw; do
  test "$(grep -Fxc "brew install --cask $cask" "$TRACE")" -eq 6
done

# Git is available before Homebrew; cloning precedes package installation.
test "$(head -n 1 "$TRACE")" = "git clone https://github.com/daiksud/dotfiles.git $HOME/.dotfiles"
! grep -Fq 'herdr plugin link ' "$TRACE"
echo 'Install-only bootstrap and updater smoke tests passed'
