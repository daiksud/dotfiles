#!/usr/bin/env zsh
set -e

plugin_dir="${0:A:h}"
source "$plugin_dir/fzf-select-ghqw.zsh"

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
mkdir -p "$tmpdir/main repository" "$tmpdir/other repository" "$tmpdir/linked worktree"

selected_spec=example/repo
gh_mode=success
expected_input="example/repo
other/repo
repo@github-com-example-repo-feature-test"
gh() {
  case "$*" in
    'qw list --all --unique')
      case "$gh_mode" in
        empty) return 0 ;;
        error)
          print -r -- 'example/repo'
          return 1 ;;
      esac
      print -r -- "$expected_input"
      ;;
    'qw list --exact --full-path example/repo')
      [[ "$gh_mode" != resolve_error ]] || return 1
      print -r -- "$tmpdir/main repository"
      ;;
    'qw list --exact --full-path other/repo')
      print -r -- "$tmpdir/other repository"
      ;;
    'qw list --exact --full-path does-not-exist')
      return 0
      ;;
    'qw list --exact --full-path --worktree repo@github-com-example-repo-feature-test')
      print -r -- "$tmpdir/linked worktree"
      ;;
    *)
      print -u2 -- "FAIL: unexpected gh arguments: $*"
      return 1
      ;;
  esac
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
    print -u2 -- "FAIL: fzf must receive short gh-qw identities"
    return 1
  }
  case "$selected_spec" in
    example/repo) print -r -- "example/repo" ;;
    other/repo) print -r -- "other/repo" ;;
    repo@github-com-example-repo-feature-test) print -r -- "repo@github-com-example-repo-feature-test" ;;
    canceled) return 130 ;;
    empty) return 1 ;;
    *) print -r -- "$selected_spec" ;;
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
selected_spec=repo@github-com-example-repo-feature-test
fzf-select-ghqw
[[ "$PWD" == "$tmpdir/linked worktree" ]] || {
  print -u2 -- "FAIL: fzf-select-ghqw did not change directories"
  exit 1
}
selected_spec=example/repo
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
selected_spec=does-not-exist
if fzf-select-ghqw; then
  print -u2 -- "FAIL: empty external selection should fail"
  exit 1
fi
[[ "$PWD" == "$tmpdir/main repository" ]] || {
  print -u2 -- "FAIL: empty selection must not change directories"
  exit 1
}
gh_mode=resolve_error
selected_spec=example/repo
if fzf-select-ghqw; then
  print -u2 -- "FAIL: failed path lookup must fail navigation"
  exit 1
fi
[[ "$PWD" == "$tmpdir/main repository" ]] || {
  print -u2 -- "FAIL: failed path lookup must not change directories"
  exit 1
}
gh_mode=error
expected_input='example/repo'
selected_spec=example/repo
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
print -r -- "ok - short gh-qw selection, path resolution, alias, and widget"
