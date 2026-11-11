#!/usr/bin/env zsh
set -e

source_dir="${0:A:h:h}"
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
export HOME="$tmpdir/home"
export XDG_CONFIG_HOME="$HOME/.config"
export GH_ACCOUNT_MAP_FILE="$XDG_CONFIG_HOME/gh-account/repos.json"
export GHQW_TEST_TRACE="$tmpdir/trace"
export GHQW_TEST_ARGS="$tmpdir/args"
mkdir -p "$HOME/.zsh" "$tmpdir/bin"
cp "$source_dir/.zsh/"{fzf-select-history,fzf-select-ghqw,gh-account}.zsh "$HOME/.zsh/"
cd "$tmpdir"

cat >"$tmpdir/bin/gh" <<'SH'
#!/bin/sh
if [ "$*" = 'qw shell-init zsh' ]; then
  printf '%s\n' "$*" >>"$GHQW_TEST_TRACE"
  printf '%s\n' 'gh() { command gh "$@"; }'
  exit 0
fi
printf '%s\n' "$@" >"$GHQW_TEST_ARGS"
exit 23
SH
for tool in sheldon starship mise; do
  printf '#!/bin/sh\nexit 0\n' >"$tmpdir/bin/$tool"
done
chmod +x "$tmpdir/bin/"*
export PATH="$tmpdir/bin:$PATH"

# Isolate the absolute Homebrew shellenv call in the startup file as well.
function /opt/homebrew/bin/brew() { :; }
source "$source_dir/.zshrc"

[[ -f "$GHQW_TEST_TRACE" && "$(cat "$GHQW_TEST_TRACE")" == 'qw shell-init zsh' ]] || {
  print -u2 -- 'FAIL: startup must request the official Zsh integration'
  exit 1
}
(( $+functions[gh] )) || {
  print -u2 -- 'FAIL: startup must load the generated gh function'
  exit 1
}
if gh api 'repos/example/repo' --jq '.name // "two words"'; then
  print -u2 -- 'FAIL: startup integration must preserve native gh exit status'
  exit 1
else
  [[ $? -eq 23 ]]
fi
[[ "$(cat "$GHQW_TEST_ARGS")" == $'api\nrepos/example/repo\n--jq\n.name // "two words"' ]] || {
  print -u2 -- 'FAIL: startup integration must preserve native gh arguments'
  exit 1
}
[[ "$aliases[gg]" == fzf-select-ghqw && "$aliases[ghu]" == gh-account-select ]]
[[ "$(bindkey '^]')" == *fzf-select-ghqw* ]]
[[ "$(bindkey '^R')" == *fzf-select-history* ]]
print -r -- 'ok - Zsh startup loads gh-qw integration and preserves gh delegation and widgets'
