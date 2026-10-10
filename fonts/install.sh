#!/usr/bin/env bash
set -euo pipefail

if brew list --cask font-moralerspace-hw >/dev/null 2>&1 || [[ -f "$HOME/Library/Fonts/MoralerspaceNeonHW-Regular.ttf" ]]; then
  exit 0
fi
brew install --cask font-moralerspace-hw
