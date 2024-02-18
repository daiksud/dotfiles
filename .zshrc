mkdir -p $HOME/.local/bin
path=($HOME/.volta/bin(N-/) /home/linuxbrew/.linuxbrew/bin(N-/) $HOME/.local/bin(N-/) $HOME/bin(N-/) /usr/local/sbin(N-/) /usr/local/bin(N-/) /usr/sbin(N-/) /usr/bin(N-/) /sbin(N-/) /bin(N-/))

autoload -U colors && colors
autoload -U compinit && compinit

######################################################################
# environment
######################################################################
export EDITOR=nvim
bindkey -e

######################################################################
# alias
######################################################################
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
eval "$(sheldon source)"

######################################################################
# other
######################################################################
if (( $+commands[direnv] )); then eval "$(direnv hook zsh)"; fi
