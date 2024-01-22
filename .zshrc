mkdir -p $HOME/.local/bin
path=($HOME/.volta/bin(N-/) /home/linuxbrew/.linuxbrew/bin(N-/) $HOME/.local/bin(N-/) $HOME/bin(N-/) /usr/local/sbin(N-/) /usr/local/bin(N-/) /usr/sbin(N-/) /usr/bin(N-/) /sbin(N-/) /bin(N-/))

autoload -U colors && colors
autoload -U compinit && compinit

#######################################################################
## tmux
#######################################################################
function is_exists() { type "$1" >/dev/null 2>&1; return $? }
function is_screen_running() { ! test -z "$STY" }
function is_tmux_runnning() { ! test -z "$TMUX" }
function is_screen_or_tmux_running() { is_screen_running || is_tmux_runnning }
function shell_has_started_interactively() { ! test -z "$PS1" }

function tmux_automatically_attach_session()
{
	if is_screen_or_tmux_running; then
		! is_exists 'tmux' && return 1

		if is_tmux_runnning; then
			echo "${fg_bold[red]} _____ __  __ _   _ __  __ ${reset_color}"
			echo "${fg_bold[red]}|_   _|  \/  | | | |\ \/ / ${reset_color}"
			echo "${fg_bold[red]}  | | | |\/| | | | | \  /  ${reset_color}"
			echo "${fg_bold[red]}  | | | |  | | |_| | /  \  ${reset_color}"
			echo "${fg_bold[red]}  |_| |_|  |_|\___/ /_/\_\ ${reset_color}"
		elif is_screen_running; then
			echo "This is on screen."
		fi
	else
		if shell_has_started_interactively; then
			if ! is_exists 'tmux'; then
				echo 'Error: tmux command not found' 2>&1
				return 1
			fi

			# アタッチされていないセッションがある場合だけ
			#if tmux has-session >/dev/null 2>&1 && tmux list-sessions | grep -qE '.*]$'; then
			# セッションが既にある場合は常に
			if tmux has-session >/dev/null 2>&1; then
				# detached session exists
				tmux list-sessions
				echo -n "Tmux: attach? (y/N/num) "
				read
				if [[ "$REPLY" =~ ^[Yy]$ ]] || [[ "$REPLY" == '' ]]; then
					exec tmux attach-session
				elif [[ "$REPLY" =~ ^[0-9]+$ ]]; then
					exec tmux attach -t "$REPLY"
				fi
			fi
			exec tmux new-session && echo "tmux created new session"
		fi
	fi
}
tmux_automatically_attach_session

######################################################################
# environment
######################################################################
export EDITOR=nvim

bindkey -e

######################################################################
# alias
######################################################################
alias zreload="exec zsh -l"
alias cdg='cd-ghq'
alias cdu='cd-gitroot'
alias ls="ls -F --color=always"

if ! which tac >/dev/null 2>&1; then
	alias tac="tail -r"
fi

if which nvim >/dev/null; then
	alias vi="nvim"
	alias vim="nvim"
else
	which nvim
fi

######################################################################
# options
######################################################################
setopt auto_cd
setopt auto_pushd
setopt correct
setopt list_packed
setopt nolistbeep
setopt IGNOREEOF
setopt auto_menu
setopt complete_aliases

######################################################################
# history
######################################################################
HISTFILE=~/.zsh_history
HISTSIZE=10000000
SAVEHIST=10000000
setopt hist_ignore_dups
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_verify
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_no_store
setopt hist_expand
setopt inc_append_history

######################################################################
# key bind
######################################################################
bindkey '^r' peco-select-history
bindkey '.' multi-dot

######################################################################
# sheldon
######################################################################
if ! which sheldon >/dev/null 2>&1; then
	curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin
	sheldon init --shell zsh
	sheldon add async --github mafredri/zsh-async
	sheldon add pure  --github sindresorhus/pure
fi
eval "$(sheldon source)"

######################################################################
# Linuxbrew
######################################################################
if ! which brew >/dev/null 2>&1; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	path=(/home/linuxbrew/.linuxbrew/bin(N-/) $path)
fi
if ! which direnv >/dev/null 2>&1; then
	brew install direnv
fi
if ! which ghq >/dev/null 2>&1; then
	brew install ghq
fi
if ! which peco >/dev/null 2>&1; then
	brew install peco
fi
if ! which pyenv >/dev/null 2>&1; then
	brew install pyenv
fi
if ! which pt >/dev/null 2>&1; then
	brew install the_platinum_searcher
fi
if ! which volta >/dev/null 2>&1; then
	brew install volta
fi

######################################################################
# other
######################################################################
if (( $+commands[direnv] )); then eval "$(direnv hook zsh)"; fi
if (( $+commands[pyenv] ));  then eval "$(pyenv init -)"; fi
