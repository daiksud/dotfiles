fzf-select-ghqw() {
  local dir
  dir="$(gh qw list --worktree --fzf)" || return
  [[ -n "$dir" ]] || return 1
  cd -- "$dir" || return
  [[ -z "${WIDGET:-}" ]] || zle reset-prompt
}

alias fgq='fzf-select-ghqw'
zle -N fzf-select-ghqw
bindkey '^]' fzf-select-ghqw
