#!/usr/bin/env zsh
set -e

plugin_dir="${0:A:h}"
source "$plugin_dir/repository-select.zsh"
source "$plugin_dir/go-to-repository.zsh"

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
mkdir -p "$tmpdir/main repository" "$tmpdir/linked worktree"

selected_spec=github.com/example/repo
gh() {
  case "$*" in
    "qw list --worktree")
      print -r -- "github.com/example/repo"
      print -r -- "github.com/example/repo@feature/test"
      ;;
    "qw list --exact --full-path github.com/example/repo")
      print -r -- "$tmpdir/main repository"
      ;;
    "qw list --worktree --exact --full-path github.com/example/repo@feature/test")
      print -r -- "$tmpdir/linked worktree"
      ;;
    *)
      print -u2 -- "unexpected gh arguments: $*"
      return 1
      ;;
  esac
}
fzf() {
  local line
  while IFS= read -r line; do
    if [[ "${line#*$'\t'}" == "$selected_spec" ]]; then
      print -r -- "$line"
      return 0
    fi
  done
  return 1
}

[[ "$(repository-select-path)" == "$tmpdir/main repository" ]] || {
  print -u2 -- "FAIL: main checkout was not resolved"
  exit 1
}
selected_spec=github.com/example/repo@feature/test
[[ "$(repository-select-path)" == "$tmpdir/linked worktree" ]] || {
  print -u2 -- "FAIL: linked worktree was not resolved"
  exit 1
}
alias ggr | grep -q go-to-repository
[[ "$(bindkey '^]')" == *go-to-repository* ]] || {
  print -u2 -- "FAIL: Ctrl+] keybinding was not restored"
  exit 1
}
cd "$tmpdir"
go-to-repository
[[ "$PWD" == "$tmpdir/linked worktree" ]] || {
  print -u2 -- "FAIL: go-to-repository did not change directories"
  exit 1
}
selected_spec=github.com/example/unknown
if repository-select-path >/dev/null 2>&1; then
  print -u2 -- "FAIL: canceled selection must fail"
  exit 1
fi
print -r -- "ok - repository selection, worktrees, alias, and widget"
