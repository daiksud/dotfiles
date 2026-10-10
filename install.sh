#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

brew bundle --file=homebrew/Brewfile
stow --no-folding --target="$HOME" git ghostty herdr nvim rumdl sheldon starship zsh
apm install --global daiksud/agents --target codex,copilot
apm compile --global
