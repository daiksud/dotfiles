function go-to-qwt-repository() {
  local query="${1:-${LBUFFER:-}}"
  local selected_dir

  selected_dir="$(gh qwt list --full-path | fzf --query "$query" --select-1 --reverse --height=20)"
  if [[ -n "$selected_dir" ]]; then
    cd "$selected_dir"

    if [[ -n "${WIDGET:-}" ]]; then
      zle reset-prompt
    fi
  fi
}

alias ggr='go-to-qwt-repository'
zle -N go-to-qwt-repository
bindkey '^]' go-to-qwt-repository
