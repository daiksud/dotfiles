#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

pkgs=(
  fish
  fzf
  git
  lazygit
  lua
  luarocks
  neovim
  ripgrep
  wget
)
brew install --quiet "${pkgs[@]}"
