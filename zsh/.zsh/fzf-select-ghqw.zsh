fzf-select-ghqw() {
  setopt local_options pipefail
  local dir
  local -a fzf_args=(--select-1 --reverse --height=20)
  (( $# )) && fzf_args+=(--query "$*")

  dir="$(gh qw list --all --full-path | fzf "${fzf_args[@]}")" || return
  [[ -n "$dir" ]] || return 1
  cd -- "$dir" || return
  [[ -z "${WIDGET:-}" ]] || zle reset-prompt
}

alias gg='fzf-select-ghqw'
zle -N fzf-select-ghqw
bindkey '^]' fzf-select-ghqw
