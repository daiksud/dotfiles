function go-to-worktree() {
  local query="${1:-${LBUFFER:-}}"
  local selected_path

  selected_path="$(gh wt list | fzf --query "$query" --select-1 --reverse --height=20 | awk '{print $1}')"
  if [[ -n "$selected_path" ]]; then
    cd "$selected_path"

    if [[ -n "${WIDGET:-}" ]]; then
      zle reset-prompt
    fi
  fi
}

alias gwt='go-to-worktree'
zle -N go-to-worktree
# No default keybinding to avoid colliding with existing bindings (^]=ggr, ^r=history search).
# Bind one yourself if desired, e.g.: bindkey '^w' go-to-worktree
