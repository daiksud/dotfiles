#!/usr/bin/env bash
set -euo pipefail

if brew list --cask gitify >/dev/null 2>&1 || [[ -d /Applications/Gitify.app ]]; then
  exit 0
fi
brew install --cask gitify
