#!/usr/bin/env bash
set -euo pipefail

if brew list --cask google-chrome >/dev/null 2>&1 || [[ -d "/Applications/Google Chrome.app" ]]; then
  exit 0
fi
brew install --cask google-chrome
