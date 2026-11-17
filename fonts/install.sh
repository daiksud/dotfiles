#!/usr/bin/env bash
set -euo pipefail

if brew list --cask font-moralerspace-hw >/dev/null 2>&1 || { [[ -f "$HOME/Library/Fonts/MoralerspaceNeonHW-Regular.ttf" ]] && [[ -f "$HOME/Library/Fonts/MoralerspaceArgonHW-Regular.ttf" ]]; }; then
  exit 0
fi
# Homebrew adopts only identical existing fonts and refuses to overwrite a
# different manual installation. This also handles a partially installed set.
brew install --cask --adopt font-moralerspace-hw
