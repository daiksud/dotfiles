function fzf-select-history() {
  BUFFER=$(history -n -r 1 | fzf --query "$LBUFFER" --height 20% --layout reverse --border --no-sort)
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history
