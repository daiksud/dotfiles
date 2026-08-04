function go-to-qwt-repository() {
  local selected_dir

  selected_dir="$(qwt-select-path "${1:-${LBUFFER:-}}" --select-1 --reverse --height=20)" || return
  cd "$selected_dir" || return

  if [[ -n "${WIDGET:-}" ]]; then
    zle reset-prompt
  fi
}

alias ggr='go-to-qwt-repository'
zle -N go-to-qwt-repository
bindkey '^]' go-to-qwt-repository
