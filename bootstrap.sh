#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
  echo "This installer requires Apple Silicon macOS." >&2
  exit 1
fi

if [[ -f "${BASH_SOURCE[0]:-}" ]]; then
  cd "$(dirname "${BASH_SOURCE[0]}")"
else
  if [[ -e "$HOME/.dotfiles" ]]; then
    git -C "$HOME/.dotfiles" pull --ff-only
  else
    git clone https://github.com/daiksud/dotfiles.git "$HOME/.dotfiles"
  fi
  cd "$HOME/.dotfiles"
fi

# Source Homebrew's shell environment for the other installers.
source ./homebrew/install.sh
./chrome/install.sh
./ghostty/install.sh
./fonts/install.sh
stow --no-folding --target="$HOME" editorconfig git ghostty herdr nvim rumdl sheldon starship zsh
apm install --global daiksud/agents --target codex,copilot
apm compile --global

gh auth status >/dev/null 2>&1 || gh auth login </dev/tty
gh extension install --force daiksud/gh-qw
gh extension install --force babarot/gh-infra

echo "Setup complete. Open Ghostty to start your configured environment."
