function run-selected-command() {
  local command_line="$1"
  shift

  if [[ -z "$command_line" || "$#" -eq 0 ]]; then
    return 1
  fi

  if [[ -n "${WIDGET:-}" ]]; then
    BUFFER="$command_line"
    CURSOR=$#BUFFER
    zle accept-line
    return 0
  fi

  print -sr -- "$command_line"
  "$@"
}
