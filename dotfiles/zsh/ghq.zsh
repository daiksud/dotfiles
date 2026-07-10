# Shortcut for `gh qwt` that reuses gh's zsh completion.
function ghq() {
  gh qwt "$@"
}

function _ghq() {
  words=(gh qwt ${words[2,-1]})
  (( CURRENT += 2 ))
  _gh
}
compdef _ghq ghq
