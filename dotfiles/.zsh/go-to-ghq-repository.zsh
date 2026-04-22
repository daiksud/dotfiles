function go-to-ghq-repository() {
  local selected_dir

  selected_dir="$(gh q -- pwd)"
  if [[ -n "$selected_dir" ]]; then
    cd "$selected_dir"

    if [[ -n "${WIDGET:-}" ]]; then
      zle reset-prompt
    fi
  fi
}

alias ggr='go-to-ghq-repository'
zle -N go-to-ghq-repository
bindkey '^]' go-to-ghq-repository
