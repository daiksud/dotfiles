#!/usr/bin/env bash
set -euo pipefail

if brew list --cask ghostty >/dev/null 2>&1 || [[ -d /Applications/Ghostty.app ]]; then
  exit 0
fi
brew install --cask ghostty
