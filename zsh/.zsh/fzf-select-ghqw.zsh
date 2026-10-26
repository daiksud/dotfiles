fzf-select-ghqw() {
  setopt local_options pipefail
  local dir selected
  local -a fzf_args=(--select-1 --reverse --height=20)
  (( $# )) && fzf_args+=(--query "$*")

  selected="$(gh qw list --all --unique | fzf "${fzf_args[@]}")" || return
  [[ -n "$selected" ]] || return 1

  local -a list_args=(--exact --full-path)
  if [[ "$selected" == *@* ]]; then
    list_args+=(--worktree)
  fi
  dir="$(gh qw list "${list_args[@]}" "$selected")" || return
  [[ -n "$dir" ]] || return 1
  cd -- "$dir" || return
  [[ -z "${WIDGET:-}" ]] || zle reset-prompt
}

alias gg='fzf-select-ghqw'
zle -N fzf-select-ghqw
bindkey '^]' fzf-select-ghqw
