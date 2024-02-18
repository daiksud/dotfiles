#!/usr/bin/zsh

# apt
sudo apt update
sudo apt install -y \
    direnv \
    neovim \
    peco

curl https://get.volta.sh | bash
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
volta install node@lts npm@latest yarn@latest pnpm@latest
