#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

pkgs=(
  ast-grep
  fd
  fish
  fzf
  git
  gs
  imagemagick
  lazygit
  lua
  luarocks
  mermaid-cli
  neovim
  ripgrep
  wget
)

brew install --quiet "${pkgs[@]}"
