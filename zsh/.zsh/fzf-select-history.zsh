function fzf-select-history() {
  BUFFER=$(history -n -r 1 | fzf --query "$LBUFFER" --no-sort)
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history
