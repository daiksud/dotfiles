#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

brew install --quiet sheldon starship

if command -v sheldon >/dev/null 2>&1; then
  sheldon lock
fi
