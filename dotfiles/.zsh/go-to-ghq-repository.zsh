function go-to-ghq-repository() {
  local query="${1:-${LBUFFER:-}}"
  local selected_dir

  selected_dir="$(gh q list | fzf --query "$query" --select-1 --reverse --height=20)"
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
