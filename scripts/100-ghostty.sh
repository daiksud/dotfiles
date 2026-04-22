#!/bin/bash

command -v ghostty >/dev/null 2>&1 && exit 0

if [ "$(uname)" = "Darwin" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  brew install --cask ghostty
else
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
fi

# Install Ghostty terminfo to ~/.terminfo so xterm-ghostty is recognized system-wide
GHOSTTY_TERMINFO="/Applications/Ghostty.app/Contents/Resources/terminfo"
if [ -d "${GHOSTTY_TERMINFO}" ]; then
  echo "Installing Ghostty terminfo to ~/.terminfo"
  cp -r "${GHOSTTY_TERMINFO}/." "${HOME}/.terminfo/"
fi
