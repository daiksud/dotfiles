function edit-ghq-repository() {
  local command_line
  local -a command_parts

  command_parts=(gh q nvim)
  command_line="${(j: :)${(@q)command_parts}}"
  run-selected-command "$command_line" "${command_parts[@]}"
}

alias egr='edit-ghq-repository'
zle -N edit-ghq-repository
