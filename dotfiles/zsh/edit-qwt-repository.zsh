function edit-qwt-repository() {
  local command_line
  local -a command_parts
  local selected_dir

  selected_dir="$(qwt-select-path "" --reverse --height=20)" || return

  command_parts=(nvim "$selected_dir")
  command_line="${(j: :)${(@q)command_parts}}"
  run-selected-command "$command_line" "${command_parts[@]}"
}

alias egr='edit-qwt-repository'
zle -N edit-qwt-repository
