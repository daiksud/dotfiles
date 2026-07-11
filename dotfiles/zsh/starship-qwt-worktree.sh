#!/bin/sh

# Print the stable qwt worktree label, or exit unsuccessfully outside qwt.
common_git_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || exit 1
[ "${common_git_dir##*/}" = ".bare" ] || exit 1

qwt_repo_dir="${common_git_dir%/.bare}"
[ -d "$qwt_repo_dir/.bare" ] && [ -f "$qwt_repo_dir/.git" ] || exit 1

gitdir_pointer="$(cat "$qwt_repo_dir/.git" 2>/dev/null)" || exit 1
case "$gitdir_pointer" in
  "gitdir: ./.bare" | "gitdir: .bare") ;;
  *) exit 1 ;;
esac

worktree="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 1
case "$worktree" in
  "$qwt_repo_dir"/*) ;;
  *) exit 1 ;;
esac

branch="${worktree#"$qwt_repo_dir"/}"
repo="${qwt_repo_dir##*/}"
owner_dir="${qwt_repo_dir%/*}"
owner="${owner_dir##*/}"

prefix="$(git rev-parse --show-prefix 2>/dev/null)" || exit 1
if [ -n "$prefix" ]; then
  printf '%s/%s/%s/%s\n' "$owner" "$repo" "$branch" "${prefix%/}"
else
  printf '%s/%s/%s\n' "$owner" "$repo" "$branch"
fi
