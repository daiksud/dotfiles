function go-to-ghq-repository() {
  local query="${1:-${LBUFFER:-}}"
  local selected_dir
  local ghq_github_root="$HOME/ghq/github.com"

  selected_dir="$(gh q list | sed "s|^${ghq_github_root}/||" | fzf --query "$query" --select-1 --reverse --height=20)"
  if [[ -n "$selected_dir" ]]; then
    if [[ "$selected_dir" != /* ]]; then
      selected_dir="${ghq_github_root}/${selected_dir}"
    fi
    cd "$selected_dir"

    if [[ -n "${WIDGET:-}" ]]; then
      zle reset-prompt
    fi
  fi
}

alias ggr='go-to-ghq-repository'
zle -N go-to-ghq-repository
bindkey '^]' go-to-ghq-repository
