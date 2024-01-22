function peco-select-history() {
	BUFFER=$(history -n 1 | tac | peco --select-1 --query "$LBUFFER")
	CURSOR=$#BUFFER
}
zle -N peco-select-history
