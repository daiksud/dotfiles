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
for app in homebrew chrome ghostty fonts; do
  mkdir -p "$SOURCE_DIR/$app"
  cp -p "$source_dir/$app/install.sh" "$SOURCE_DIR/$app/install.sh"
done
cp "$source_dir/homebrew/Brewfile" "$SOURCE_DIR/homebrew/Brewfile"
for app in chrome ghostty; do
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
  mkdir -p "$3/homebrew" "$3/chrome" "$3/ghostty" "$3/fonts" "$3/.git"
  cp "$SOURCE_DIR/homebrew/Brewfile" "$3/homebrew/Brewfile"
  for app in homebrew chrome ghostty fonts; do
    cp -p "$SOURCE_DIR/$app/install.sh" "$3/$app/install.sh"
  done
fi
SH

cat >"$tmp/bin/gh" <<'SH'
#!/usr/bin/env bash
if [[ "$1 $2" == 'auth status' ]]; then
  exit 0
fi
printf 'gh %s\n' "$*" >>"$TRACE"
SH

for tool in stow apm; do
  cat >"$tmp/bin/$tool" <<'SH'
#!/usr/bin/env bash
printf '%s %s\n' "${0##*/}" "$*" >>"$TRACE"
SH
done
chmod +x "$tmp/bin/"*

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
grep -Fx "git -C $HOME/.dotfiles pull --ff-only" "$TRACE"
test "$(grep -Fc 'brew bundle --no-upgrade --file=' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask google-chrome' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask ghostty' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask font-moralerspace-hw' "$TRACE")" -eq 3
test "$(grep -Fc 'apm compile --global' "$TRACE")" -eq 3
test "$(grep -Fc 'gh extension install --force daiksud/gh-qw' "$TRACE")" -eq 3
test "$(grep -Fc 'gh extension install --force babarot/gh-infra' "$TRACE")" -eq 3
grep -F 'stow --no-folding --target=' "$TRACE" | grep -q 'editorconfig git ghostty herdr nvim rumdl sheldon starship zsh'
# Standalone installers do not reinstall casks already managed by Homebrew.
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=google-chrome bash chrome/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=ghostty bash ghostty/install.sh)
(cd "$SOURCE_DIR" && BREW_INSTALLED_CASK=font-moralerspace-hw bash fonts/install.sh)
test "$(grep -Fc 'brew install --cask google-chrome' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask ghostty' "$TRACE")" -eq 3
test "$(grep -Fc 'brew install --cask font-moralerspace-hw' "$TRACE")" -eq 3

# Git is available before Homebrew; cloning precedes package installation.
test "$(head -n 1 "$TRACE")" = "git clone https://github.com/daiksud/dotfiles.git $HOME/.dotfiles"

echo 'Modular bootstrap and repeat-run smoke tests passed'
