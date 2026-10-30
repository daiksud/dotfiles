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
mkdir -p "$SOURCE_DIR/.git"
for app in homebrew chrome chatgpt ghostty gitify fonts; do
  mkdir -p "$SOURCE_DIR/$app"
  cp -p "$source_dir/$app/install.sh" "$SOURCE_DIR/$app/install.sh"
done
cp "$source_dir/homebrew/Brewfile" "$SOURCE_DIR/homebrew/Brewfile"
mkdir -p "$SOURCE_DIR/plugins/herdr-tab-status"
cp "$source_dir/plugins/herdr-tab-status/herdr-plugin.toml" "$SOURCE_DIR/plugins/herdr-tab-status/herdr-plugin.toml"
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
  cp "$SOURCE_DIR/homebrew/Brewfile" "$3/homebrew/Brewfile"
  for app in homebrew chrome chatgpt ghostty gitify fonts; do
    cp -p "$SOURCE_DIR/$app/install.sh" "$3/$app/install.sh"
  done
  mkdir -p "$3/plugins/herdr-tab-status"
  cp "$SOURCE_DIR/plugins/herdr-tab-status/herdr-plugin.toml" "$3/plugins/herdr-tab-status/herdr-plugin.toml"
fi
if [[ "$1" == -C && "$3" == pull && -n "${MOCK_UPDATED_BOOTSTRAP:-}" && "$2" == "$SOURCE_DIR" ]]; then
  cp "$MOCK_UPDATED_BOOTSTRAP" "$2/bootstrap.sh.new"
  mv "$2/bootstrap.sh.new" "$2/bootstrap.sh"
fi
SH

cat >"$tmp/bin/gh" <<'SH'
#!/usr/bin/env bash
if [[ "$1 $2" == 'auth status' ]]; then
  exit 0
fi
printf 'gh %s\n' "$*" >>"$TRACE"
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
  'plugin link')
    [[ "$3" == "$SOURCE_DIR/plugins/herdr-tab-status" || "$3" == "$HOME/.dotfiles/plugins/herdr-tab-status" ]] || exit 2
    [[ -f "$3/herdr-plugin.toml" ]] || exit 2
    grep -Fq 'command = ["/usr/bin/perl", "sync.pl"]' "$3/herdr-plugin.toml" || exit 2
    touch "$HOME/.mock-herdr-daiksud.tab-agent-status"
    ;;
  'plugin uninstall')
    [[ "$3" == dev-shimada.auto-tab-name ]] || exit 2
    rm -f "$HOME/.mock-herdr-dev-shimada.auto-tab-name"
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
SH
done
chmod +x "$tmp/bin/"*
# Simulate a previously installed remote tab-name plugin for upgrade coverage.
touch "$HOME/.mock-herdr-dev-shimada.auto-tab-name"

# A streamed bootstrap clones the checkout. Running it again pulls safely.
(cd "$tmp" && cat "$SOURCE_DIR/bootstrap.sh" | bash)
(cd "$tmp" && cat "$SOURCE_DIR/bootstrap.sh" | bash)
# Executing the checkout script from a different directory uses its own location.
(cd "$tmp" && bash "$SOURCE_DIR/bootstrap.sh")

# An unrelated existing directory is never overwritten by the remote installer.
mkdir -p "$tmp/occupied/.dotfiles"
if (cd "$tmp" && cat "$SOURCE_DIR/bootstrap.sh" | HOME="$tmp/occupied" bash) >/dev/null 2>&1; then
  echo 'FAIL: existing unmanaged checkout was overwritten' >&2
  exit 1
fi

grep -Fx "git clone https://github.com/daiksud/dotfiles.git $HOME/.dotfiles" "$TRACE"
test "$(grep -Fxc "git -C $HOME/.dotfiles pull --ff-only" "$TRACE")" -eq 1
test "$(grep -Fxc "git -C $SOURCE_DIR pull --ff-only" "$TRACE")" -eq 1
test "$(grep -Fc 'brew bundle --no-upgrade --file=' "$TRACE")" -eq 3
test "$(grep -Fxc 'brew upgrade --no-ask' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask gitify' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask chatgpt' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask google-chrome' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask ghostty' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask font-moralerspace-hw' "$TRACE")" -eq 3
test "$(grep -Fxc "herdr plugin link $HOME/.dotfiles/plugins/herdr-tab-status" "$TRACE")" -eq 2
test "$(grep -Fxc "herdr plugin link $SOURCE_DIR/plugins/herdr-tab-status" "$TRACE")" -eq 3
test "$(grep -Fxc 'herdr plugin uninstall dev-shimada.auto-tab-name' "$TRACE")" -eq 1
test "$(grep -Fxc 'herdr plugin list --plugin daiksud.tab-agent-status --json' "$TRACE")" -eq 0
test "$(grep -Fxc 'herdr plugin list --plugin dev-shimada.auto-tab-name --json' "$TRACE")" -eq 3
test ! -f "$HOME/.mock-herdr-dev-shimada.auto-tab-name"
test -f "$HOME/.mock-herdr-daiksud.tab-agent-status"
test "$(grep -Fxc 'herdr plugin install shibayu36/herdr-equalize-panes --ref 0c1d940e9af09c632a48a5b179753ef25056ff13 --yes' "$TRACE")" -eq 1
test "$(grep -Fxc 'herdr plugin list --plugin shibayu36.equalize-panes --json' "$TRACE")" -eq 3
test "$(grep -Fxc 'apm install --global daiksud/agents --target codex,copilot' "$TRACE")" -eq 3
test "$(grep -Fxc 'apm update --global --yes' "$TRACE")" -eq 3
test "$(grep -Fxc 'apm compile --global' "$TRACE")" -eq 3
test "$(grep -Fxc 'apm outdated --global' "$TRACE")" -eq 3
test "$(grep '^apm ' "$TRACE" | head -n 4)" = "$(printf 'apm install --global daiksud/agents --target codex,copilot\napm update --global --yes\napm compile --global\napm outdated --global\n')"
test "$(grep -Fc 'gh extension install --force daiksud/gh-qw' "$TRACE")" -eq 3
test "$(grep -Fxc 'gh extension install --force daiksud/gh-settings' "$TRACE")" -eq 3
test "$(grep -Fc 'gh extension install --force babarot/gh-infra' "$TRACE")" -eq 3
grep -F 'stow --no-folding --target=' "$TRACE" | grep -q 'editorconfig git ghostty herdr nvim rumdl sheldon starship zsh'
# Standalone installers do not reinstall casks already managed by Homebrew.
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=gitify bash gitify/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=chatgpt bash chatgpt/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=google-chrome bash chrome/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=ghostty bash ghostty/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=font-moralerspace-hw bash fonts/install.sh)
test "$(grep -Fc 'brew install --cask google-chrome' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask ghostty' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask font-moralerspace-hw' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask chatgpt' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask gitify' "$TRACE")" -eq 3

# Standalone installers also preserve manually installed applications and fonts.
mkdir -p "$tmp/Applications/Gitify.app" "$tmp/Applications/ChatGPT.app" "$tmp/Applications/Google Chrome.app" "$tmp/Applications/Ghostty.app" "$HOME/Library/Fonts"
touch "$HOME/Library/Fonts/MoralerspaceNeonHW-Regular.ttf"
for app in chrome chatgpt ghostty gitify fonts; do
  (cd "$SOURCE_DIR" && BREW_INSTALLED_CASK= bash "$app/install.sh")
done
test "$(grep -Fc 'brew install --cask google-chrome' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask ghostty' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask font-moralerspace-hw' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask chatgpt' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask gitify' "$TRACE")" -eq 3

# Git is available before Homebrew; cloning precedes package installation.
test "$(head -n 1 "$TRACE")" = "git clone https://github.com/daiksud/dotfiles.git $HOME/.dotfiles"

# A local bootstrap must use the fetched script, not resume its stale contents.
cp "$SOURCE_DIR/bootstrap.sh" "$tmp/updated-bootstrap.sh"
printf '\nprintf "stale bootstrap continued\\n" >>"$TRACE"\n' >>"$SOURCE_DIR/bootstrap.sh"
(cd "$tmp" && MOCK_UPDATED_BOOTSTRAP="$tmp/updated-bootstrap.sh" bash "$SOURCE_DIR/bootstrap.sh")
test "$(grep -Fxc "git -C $SOURCE_DIR pull --ff-only" "$TRACE")" -eq 2
test "$(grep -Fxc "herdr plugin link $HOME/.dotfiles/plugins/herdr-tab-status" "$TRACE")" -eq 2
test "$(grep -Fxc "herdr plugin link $SOURCE_DIR/plugins/herdr-tab-status" "$TRACE")" -eq 2
test "$(grep -Fxc 'herdr plugin uninstall dev-shimada.auto-tab-name' "$TRACE")" -eq 1
test "$(grep -Fxc 'herdr plugin list --plugin daiksud.tab-agent-status --json' "$TRACE")" -eq 0
test "$(grep -Fxc 'herdr plugin list --plugin dev-shimada.auto-tab-name --json' "$TRACE")" -eq 4
test "$(grep -Fxc 'herdr plugin install shibayu36/herdr-equalize-panes --ref 0c1d940e9af09c632a48a5b179753ef25056ff13 --yes' "$TRACE")" -eq 1
test "$(grep -Fxc 'herdr plugin list --plugin shibayu36.equalize-panes --json' "$TRACE")" -eq 4
test "$(grep -Fxc 'apm install --global daiksud/agents --target codex,copilot' "$TRACE")" -eq 4
test "$(grep -Fxc 'apm update --global --yes' "$TRACE")" -eq 4
test "$(grep -Fxc 'apm compile --global' "$TRACE")" -eq 4
test "$(grep -Fxc 'apm outdated --global' "$TRACE")" -eq 4
if grep -Fq 'stale bootstrap continued' "$TRACE"; then
  echo 'FAIL: bootstrap continued executing stale content after update' >&2
  exit 1
fi

# A fresh install links the local plugin without attempting to remove a legacy one.
mkdir -p "$tmp/fresh-home"
(cd "$tmp" && HOME="$tmp/fresh-home" bash "$SOURCE_DIR/bootstrap.sh")
test "$(grep -Fxc "herdr plugin link $SOURCE_DIR/plugins/herdr-tab-status" "$TRACE")" -eq 1
test "$(grep -Fxc 'herdr plugin uninstall dev-shimada.auto-tab-name' "$TRACE")" -eq 1
test -f "$tmp/fresh-home/.mock-herdr-daiksud.tab-agent-status"

echo 'Modular bootstrap and repeat-run smoke tests passed'
