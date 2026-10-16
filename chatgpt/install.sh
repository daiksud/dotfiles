#!/usr/bin/env bash
set -euo pipefail

if brew list --cask chatgpt >/dev/null 2>&1 || [[ -d /Applications/ChatGPT.app ]]; then
  exit 0
fi
brew install --cask chatgpt
