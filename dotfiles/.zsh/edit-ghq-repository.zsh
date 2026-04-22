function edit-ghq-repository() {
  local query="${LBUFFER:-}"
  local ghq_root
  local selected_repo
  local selected_dir
  local command_line
  local -a command_parts

  ghq_root="$(ghq root)"
  selected_repo="$(ghq list | rg -v '^\.' | fzf --query "$query")"

  if [[ -n "$selected_repo" ]]; then
    selected_dir="$ghq_root/$selected_repo"
    command_parts=(nvim "$selected_dir")
    command_line="${(j: :)${(@q)command_parts}}"
    run-selected-command "$command_line" "${command_parts[@]}"
  elif [[ -n "${WIDGET:-}" ]]; then
    zle reset-prompt
  fi
}

alias egr='edit-ghq-repository'
zle -N edit-ghq-repository
