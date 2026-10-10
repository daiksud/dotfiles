function go-to-repository() {
  local selected_dir

  selected_dir="$(repository-select-path "${1:-${LBUFFER:-}}" --select-1 --reverse --height=20)" || return
  cd "$selected_dir" || return

  if [[ -n "${WIDGET:-}" ]]; then
    zle reset-prompt
  fi
}

alias ggr='go-to-repository'
zle -N go-to-repository
bindkey '^]' go-to-repository
