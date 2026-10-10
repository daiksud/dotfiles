# Shared fzf selector for gh-qw managed checkouts and linked worktrees.
#
# `gh qw` has no path-resolving command, so selection is a two-step lookup:
# list identities with `gh qw list --worktree`, then resolve the chosen
# identity to an absolute path with `gh qw list ... --exact --full-path`.
# `--worktree --exact` without an `@<branch>` suffix matches a repository's
# main worktree *and* every linked worktree, so an `@`-less spec is resolved
# without `--worktree` to keep the match to the main worktree only.
function repository-select-path() {
  local query="${1:-}"
  (( $# > 0 )) && shift
  local -a fzf_args=("$@")
  local listing line spec resolved

  if ! command -v gh >/dev/null 2>&1; then
    print -u2 -- "repository-select-path: gh is not installed"
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 -- "repository-select-path: fzf is not installed"
    return 1
  fi

  if ! listing="$(gh qw list --worktree 2>/dev/null)" || [[ -z "$listing" ]]; then
    print -u2 -- "repository-select-path: no gh-qw managed checkouts found"
    return 1
  fi

  # Display without the github.com/ prefix, but keep the canonical spec in a
  # hidden second field so other hosts stay unambiguous when resolving.
  line="$(printf '%s\n' "$listing" \
    | awk -F'\t' '{ display = $0; sub(/^github\.com\//, "", display); printf "%s\t%s\n", display, $0 }' \
    | fzf --delimiter=$'\t' --with-nth=1 --query "$query" "${fzf_args[@]}")" || return 1
  [[ -n "$line" ]] || return 1

  spec="${line#*$'\t'}"
  if [[ "$spec" == *@* ]]; then
    resolved="$(gh qw list --worktree --exact --full-path "$spec" 2>/dev/null)"
  else
    resolved="$(gh qw list --exact --full-path "$spec" 2>/dev/null)"
  fi
  # `list` exits 0 even with no match, so an empty result is the failure
  # signal here, not a nonzero exit status.
  if [[ -z "$resolved" ]]; then
    print -u2 -- "repository-select-path: could not resolve a path for '${spec}'"
    return 1
  fi
  resolved="${resolved%%$'\n'*}"

  if [[ ! -d "$resolved" ]]; then
    print -u2 -- "repository-select-path: '${resolved}' does not exist"
    return 1
  fi

  print -r -- "$resolved"
}
