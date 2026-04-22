#!/bin/bash

FILE=$(readlink -f "$0")
DIR=$(dirname "${FILE}")

if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

HOMEBREW_BUNDLE_NO_LOCK=1 brew bundle --file="${DIR}/../Brewfile"
