# Auto-attach or create tmux session (exit shell when tmux exits)
if [[ -z "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s main
fi

# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Completion system (must be before sheldon so plugins can use compdef)
autoload -Uz compinit
compinit

# Emacs keybindings
bindkey -e

# Sheldon plugin manager
eval "$(sheldon source)"

# History
setopt extended_history
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_verify
setopt share_history

# Directory
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups

# Completion style (case-insensitive, hyphen-insensitive)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}'

# Editor
export EDITOR='nvim'

# Starship prompt
eval "$(starship init zsh)"

# mise (runtime version manager)
eval "$(mise activate zsh)"

# Custom functions
if [[ -d $HOME/.zsh ]]; then
  for file in $HOME/.zsh/*.zsh; do
    source "$file"
  done
fi
