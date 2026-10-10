#!/usr/bin/env zsh
set -e

source "${0:A:h}/fzf-select-history.zsh"

[[ "$(bindkey '^r')" == *fzf-select-history* ]] || {
  print -u2 -- "FAIL: Ctrl+R binding was not restored"
  exit 1
}

history() {
  [[ "$*" == "-n -r 1" ]] || return 1
  print -r -- "git status"
  print -r -- "git log --oneline"
}
fzf() {
  [[ "$*" == "--query gh --height 20% --layout reverse --border --no-sort" ]] || return 1
  local first
  IFS= read -r first
  [[ "$first" == "git status" ]] || return 1
  print -r -- "git status"
}
zle() {
  [[ "$*" == "reset-prompt" ]]
}

LBUFFER=gh
BUFFER=previous
CURSOR=3
fzf-select-history
[[ "$BUFFER" == "git status" && "$CURSOR" == ${#BUFFER} ]] || {
  print -u2 -- "FAIL: fzf selection must populate the ZLE buffer and move the cursor"
  exit 1
}

print -r -- "ok - Ctrl+R history widget and fzf selection"
