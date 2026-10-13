#!/usr/bin/env zsh
set -e

plugin_dir="${0:A:h}"
source "$plugin_dir/fzf-select-ghqw.zsh"

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
mkdir -p "$tmpdir/main repository" "$tmpdir/linked worktree"

selected_spec=github.com/example/repo
gh() {
  [[ "$*" == "qw list --worktree --fzf" ]] || {
    print -u2 -- "unexpected gh arguments: $*"
    return 1
  }
  [[ "$FZF_DEFAULT_OPTS" == "--border --select-1 --reverse --height=20" ]] || {
    print -u2 -- "FAIL: fzf options must preserve existing defaults"
    return 1
  }
  case "$selected_spec" in
    github.com/example/repo) print -r -- "$tmpdir/main repository" ;;
    github.com/example/repo@feature/test) print -r -- "$tmpdir/linked worktree" ;;
    canceled) return 130 ;;
  esac
}

FZF_DEFAULT_OPTS=--border
alias gg | grep -q fzf-select-ghqw
if alias fgq >/dev/null 2>&1; then
  print -u2 -- "FAIL: fgq alias should no longer exist"
  exit 1
fi
[[ "$(bindkey '^]')" == *fzf-select-ghqw* ]] || {
  print -u2 -- "FAIL: Ctrl+] keybinding must invoke fzf-select-ghqw"
  exit 1
}

cd "$tmpdir"
selected_spec=github.com/example/repo@feature/test
fzf-select-ghqw
[[ "$PWD" == "$tmpdir/linked worktree" ]] || {
  print -u2 -- "FAIL: fzf-select-ghqw did not change directories"
  exit 1
}
selected_spec=github.com/example/repo
fzf-select-ghqw
[[ "$PWD" == "$tmpdir/main repository" ]] || {
  print -u2 -- "FAIL: fzf-select-ghqw did not select the main checkout"
  exit 1
}
[[ "$FZF_DEFAULT_OPTS" == --border ]] || {
  print -u2 -- "FAIL: fzf-select-ghqw modified global fzf options"
  exit 1
}
selected_spec=canceled
if fzf-select-ghqw; then
  print -u2 -- "FAIL: canceled native selector should fail"
  exit 1
fi
[[ "$PWD" == "$tmpdir/main repository" ]] || {
  print -u2 -- "FAIL: canceled selection must not change directories"
  exit 1
}
selected_spec=github.com/example/unknown
if fzf-select-ghqw; then
  print -u2 -- "FAIL: empty native selection should fail"
  exit 1
fi
[[ "$PWD" == "$tmpdir/main repository" ]] || {
  print -u2 -- "FAIL: empty selection must not change directories"
  exit 1
}
print -r -- "ok - native fzf gh-qw navigation, alias, and widget"
