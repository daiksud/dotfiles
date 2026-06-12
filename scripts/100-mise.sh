#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [[ -L ~/.config/mise ]]; then
  rm ~/.config/mise
fi
mkdir -p ~/.config/mise
mise settings set github.credential_command "gh auth token"
mise install
