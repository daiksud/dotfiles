autoload -U colors && colors
autoload -U compinit && compinit

export EDITOR=nvim
bindkey -e

# options
setopt auto_cd
setopt auto_pushd
setopt correct
setopt list_packed
setopt nolistbeep
setopt IGNOREEOF
setopt auto_menu
setopt complete_aliases

# history
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

# key bind
bindkey '^r' peco-select-history
bindkey '.' multi-dot
