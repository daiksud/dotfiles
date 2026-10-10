# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

autoload -Uz compinit
compinit
bindkey -e

# Ghostty remaps Ctrl+E and Ctrl+D to End and Delete.
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
setopt ignore_eof hist_ignore_all_dups hist_ignore_space share_history auto_cd
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}'

export EDITOR=nvim

eval "$(sheldon source)"
eval "$(starship init zsh)"
eval "$(mise activate zsh)"

# Custom history search, repository navigation, and GitHub identities.
[[ -f "$HOME/.zsh/fzf-select-history.zsh" ]] && source "$HOME/.zsh/fzf-select-history.zsh"
[[ -f "$HOME/.zsh/repository-select.zsh" ]] && source "$HOME/.zsh/repository-select.zsh"
[[ -f "$HOME/.zsh/go-to-repository.zsh" ]] && source "$HOME/.zsh/go-to-repository.zsh"
[[ -f "$HOME/.zsh/gh-account.zsh" ]] && source "$HOME/.zsh/gh-account.zsh"
