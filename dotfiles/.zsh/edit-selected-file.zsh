function edit-selected-file() {
  local selected_file
  local command_line
  local -a command_parts

  selected_file="$(fzf --reverse --height=20)"
  if [[ -n "$selected_file" ]]; then
    command_parts=(nvim "$selected_file")
    command_line="${(j: :)${(@q)command_parts}}"
    run-selected-command "$command_line" "${command_parts[@]}"
  elif [[ -n "${WIDGET:-}" ]]; then
    zle reset-prompt
  fi
}

alias esf='edit-selected-file'
zle -N edit-selected-file
