function cd-ghq () {
	if [ $# = 0 ]; then
		cd $(ghq list -p | peco --select-1)
	else
		cd $(ghq list -p | peco --select-1 --query="$*")
	fi
}
