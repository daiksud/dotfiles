#!/usr/bin/env zsh
set -e

plugin_dir="${0:A:h}"
source "$plugin_dir/fzf-select-ghqw.zsh"

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
mkdir -p "$tmpdir/main repository" "$tmpdir/linked worktree"

selected_spec=github.com/example/repo
gh_mode=success
expected_input="$tmpdir/main repository
$tmpdir/linked worktree"
gh() {
  [[ "$*" == "qw list --all --full-path" ]] || {
    print -u2 -- "unexpected gh arguments: $*"
    return 1
  }
  case "$gh_mode" in
    empty) return 0 ;;
    error)
      print -r -- "$tmpdir/main repository"
      return 1
      ;;
  esac
  print -r -- "$tmpdir/main repository"
  print -r -- "$tmpdir/linked worktree"
}
fzf() {
  [[ "${(j:|:)@}" == "$expected_fzf_args" ]] || {
    print -u2 -- "FAIL: unexpected fzf arguments: ${(j:|:)@}"
    return 1
  }
  [[ "$FZF_DEFAULT_OPTS" == --border ]] || {
    print -u2 -- "FAIL: fzf must inherit existing default options"
    return 1
  }
  local input="$(cat)"
  [[ "$input" == "$expected_input" ]] || {
    print -u2 -- "FAIL: fzf must receive gh-qw paths"
    return 1
  }
  case "$selected_spec" in
    github.com/example/repo) print -r -- "$tmpdir/main repository" ;;
    github.com/example/repo@feature/test) print -r -- "$tmpdir/linked worktree" ;;
    canceled) return 130 ;;
    empty) return 1 ;;
  esac
}
FZF_DEFAULT_OPTS=--border
expected_fzf_args='--select-1|--reverse|--height=20'
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
expected_fzf_args='--select-1|--reverse|--height=20|--query|example'
fzf-select-ghqw example
[[ "$PWD" == "$tmpdir/main repository" ]] || {
  print -u2 -- "FAIL: initial query should not affect directory selection"
  exit 1
}
expected_fzf_args='--select-1|--reverse|--height=20|--query|feature test'
fzf-select-ghqw "feature test"
fzf-select-ghqw feature test
expected_fzf_args='--select-1|--reverse|--height=20'
[[ "$FZF_DEFAULT_OPTS" == --border ]] || {
  print -u2 -- "FAIL: fzf-select-ghqw modified global fzf options"
  exit 1
}
selected_spec=canceled
if fzf-select-ghqw; then
  print -u2 -- "FAIL: canceled external selector should fail"
  exit 1
fi
[[ "$PWD" == "$tmpdir/main repository" ]] || {
  print -u2 -- "FAIL: canceled selection must not change directories"
  exit 1
}
selected_spec=github.com/example/unknown
if fzf-select-ghqw; then
  print -u2 -- "FAIL: empty external selection should fail"
  exit 1
fi
[[ "$PWD" == "$tmpdir/main repository" ]] || {
  print -u2 -- "FAIL: empty selection must not change directories"
  exit 1
}
gh_mode=error
expected_input="$tmpdir/main repository"
selected_spec=github.com/example/repo
if fzf-select-ghqw; then
  print -u2 -- "FAIL: failed gh-qw listing must fail navigation"
  exit 1
fi
[[ "$PWD" == "$tmpdir/main repository" ]] || {
  print -u2 -- "FAIL: failed gh-qw listing must not change directories"
  exit 1
}
gh_mode=empty
expected_input=''
selected_spec=empty
if fzf-select-ghqw; then
  print -u2 -- "FAIL: empty gh-qw listing must fail navigation"
  exit 1
fi
[[ "$PWD" == "$tmpdir/main repository" ]] || {
  print -u2 -- "FAIL: empty gh-qw listing must not change directories"
  exit 1
}
print -r -- "ok - external fzf gh-qw navigation, alias, and widget"
