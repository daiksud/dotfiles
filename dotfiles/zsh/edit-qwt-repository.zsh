function edit-qwt-repository() {
  local command_line
  local -a command_parts
  local selected_dir

  selected_dir="$(gh qwt list | fzf --reverse --height=20)"
  if [[ -z "$selected_dir" ]]; then
    return
  fi

  if [[ "$selected_dir" != /* ]]; then
    selected_dir="$(gh qwt root)/${selected_dir}"
  fi

  command_parts=(nvim "$selected_dir")
  command_line="${(j: :)${(@q)command_parts}}"
  run-selected-command "$command_line" "${command_parts[@]}"
}

alias egr='edit-qwt-repository'
zle -N edit-qwt-repository
