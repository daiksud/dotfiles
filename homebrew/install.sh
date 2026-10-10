#!/usr/bin/env bash
set -euo pipefail

brew_bin="$(command -v brew || true)"
if [[ -z "$brew_bin" && -x /opt/homebrew/bin/brew ]]; then
  brew_bin=/opt/homebrew/bin/brew
fi
if [[ -z "$brew_bin" ]]; then
  echo "Installing Homebrew (macOS may request administrator approval)..."
  installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  /bin/bash -c "$installer" </dev/tty
  brew_bin=/opt/homebrew/bin/brew
fi
if [[ ! -x "$brew_bin" ]]; then
  echo "Homebrew installation did not provide $brew_bin." >&2
  exit 1
fi
eval "$("$brew_bin" shellenv)"
brew bundle --no-upgrade --file="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/Brewfile"
