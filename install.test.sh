#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home"
export HOME="$tmp/home" TRACE="$tmp/trace" SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
export PATH="$tmp/bin:$PATH"

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
else
  printf 'brew %s\n' "$*" >>"$TRACE"
fi
SH

cat >"$tmp/bin/git" <<'SH'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >>"$TRACE"
if [[ "$1" == clone ]]; then
  mkdir -p "$3/homebrew" "$3/.git"
  cp "$SOURCE_DIR/homebrew/Brewfile" "$3/homebrew/Brewfile"
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

# A streamed installer clones the checkout. Running it again pulls safely.
(cd "$tmp" && cat "$SOURCE_DIR/install.sh" | bash)
(cd "$tmp" && cat "$SOURCE_DIR/install.sh" | bash)
# A checkout-local execution does not clone or pull.
(cd "$SOURCE_DIR" && bash ./install.sh)

# An unrelated existing directory is never overwritten by the remote installer.
mkdir -p "$tmp/occupied/.dotfiles"
if (cd "$tmp" && cat "$SOURCE_DIR/install.sh" | HOME="$tmp/occupied" bash) >/dev/null 2>&1; then
  echo 'FAIL: existing unmanaged checkout was overwritten' >&2
  exit 1
fi

grep -Fx "git clone https://github.com/daiksud/dotfiles.git $HOME/.dotfiles" "$TRACE"
grep -Fx "git -C $HOME/.dotfiles pull --ff-only" "$TRACE"
test "$(grep -Fc 'brew bundle --no-upgrade --file=homebrew/Brewfile' "$TRACE")" -eq 3
test "$(grep -Fc 'apm compile --global' "$TRACE")" -eq 3
test "$(grep -Fc 'gh extension install --force daiksud/gh-qw' "$TRACE")" -eq 3
test "$(grep -Fc 'gh extension install --force babarot/gh-infra' "$TRACE")" -eq 3
grep -F 'stow --no-folding --target=' "$TRACE" | grep -q 'editorconfig git ghostty herdr nvim rumdl sheldon starship zsh'
grep -Fx 'cask "ghostty"' "$SOURCE_DIR/homebrew/Brewfile"
grep -Fx 'cask "font-moralerspace-hw"' "$SOURCE_DIR/homebrew/Brewfile"
echo 'Bootstrap and repeat-run smoke tests passed'
