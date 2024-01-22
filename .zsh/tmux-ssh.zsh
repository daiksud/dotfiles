function tmux_ssh() {
	ssh_cmd="ssh $@"
	tmux new-window -n "$*" "$ssh_cmd"
}

if [ "" = "$SSH_CONNECTION" ]; then
	compdef tmux_ssh='ssh'
	alias ssh=tmux_ssh
fi
