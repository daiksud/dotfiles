fzf-select-ghqw() {
  local dir
  dir="$(FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--select-1 --reverse --height=20" gh qw list --worktree --fzf)" || return
  [[ -n "$dir" ]] || return 1
  cd -- "$dir" || return
  [[ -z "${WIDGET:-}" ]] || zle reset-prompt
}

alias fgq='fzf-select-ghqw'
zle -N fzf-select-ghqw
bindkey '^]' fzf-select-ghqw
