#!/usr/bin/zsh

# apt
sudo apt update
sudo apt install -y \
    neovim

# sheldon
curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin
path=(/home/codespace/.local/bin(N-/) $path)
sheldon init --shell zsh

# Linuxbrew
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
path=(/home/linuxbrew/.linuxbrew/bin(N-/) $path)
brew install \
    direnv \
    peco \
    volta
