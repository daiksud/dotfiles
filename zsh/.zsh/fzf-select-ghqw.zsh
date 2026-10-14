fzf-select-ghqw() {
  local dir query opts
  opts="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--select-1 --reverse --height=20"
  if (( $# )); then
    query="$*"
    opts+=" --query=${(q)query}"
  fi
  dir="$(FZF_DEFAULT_OPTS="$opts" gh qw list --worktree --fzf)" || return
  [[ -n "$dir" ]] || return 1
  cd -- "$dir" || return
  [[ -z "${WIDGET:-}" ]] || zle reset-prompt
}

alias gg='fzf-select-ghqw'
zle -N fzf-select-ghqw
bindkey '^]' fzf-select-ghqw
