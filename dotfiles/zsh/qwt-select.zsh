# Shared fzf selector for gh-qwt managed checkouts and linked worktrees.
#
# `gh qwt list` is scoped to the current repository and fails outside the ghq
# roots, so every selection uses `--all`. Its output is host-qualified
# (`github.com/<owner>/<repo>/<branch>`), and only `gh qwt path` can turn that
# into an absolute path: primary checkouts live under the ghq root while linked
# worktrees live under a separate `<ghq-root>-worktrees` tree.
function qwt-select-path() {
  local query="${1:-}"
  shift
  local -a fzf_args=("$@")
  local listing line spec resolved

  if ! command -v gh >/dev/null 2>&1; then
    print -u2 -- "qwt-select-path: gh is not installed"
    return 1
  fi

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 -- "qwt-select-path: fzf is not installed"
    return 1
  fi

  if ! listing="$(gh qwt list --all 2>/dev/null)" || [[ -z "$listing" ]]; then
    print -u2 -- "qwt-select-path: no gh-qwt managed worktrees found"
    return 1
  fi

  # Display without the github.com prefix, but keep the canonical spec in a
  # hidden second field so other hosts stay unambiguous when resolving.
  line="$(printf '%s\n' "$listing" \
    | awk -F'\t' '{ display = $0; sub(/^github\.com\//, "", display); printf "%s\t%s\n", display, $0 }' \
    | fzf --delimiter=$'\t' --with-nth=1 --query "$query" "${fzf_args[@]}")" || return 1
  [[ -n "$line" ]] || return 1

  spec="${line#*$'\t'}"
  if ! resolved="$(gh qwt path "$spec" 2>/dev/null)" || [[ -z "$resolved" ]]; then
    print -u2 -- "qwt-select-path: could not resolve a path for '${spec}'"
    return 1
  fi

  # `gh qwt path` also prints deterministic paths for worktrees that do not
  # exist yet, so existence has to be confirmed separately.
  if [[ ! -d "$resolved" ]]; then
    print -u2 -- "qwt-select-path: '${resolved}' does not exist"
    return 1
  fi

  print -r -- "$resolved"
}
