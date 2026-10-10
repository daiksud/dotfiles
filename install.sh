#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
  echo "This installer requires Apple Silicon macOS." >&2
  exit 1
fi

brew_bin=/opt/homebrew/bin/brew
if [[ ! -x "$brew_bin" ]]; then
  brew_bin="$(command -v brew || true)"
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
brew_env="$("$brew_bin" shellenv)"
eval "$brew_env"

if [[ -f "${BASH_SOURCE[0]:-}" && -f "$(dirname "${BASH_SOURCE[0]:-}")/homebrew/Brewfile" ]]; then
  cd "$(dirname "${BASH_SOURCE[0]:-}")"
else
  if [[ -d "$HOME/.dotfiles/.git" ]]; then
    git -C "$HOME/.dotfiles" pull --ff-only
  elif [[ -e "$HOME/.dotfiles" ]]; then
    echo "Cannot clone: $HOME/.dotfiles exists and is not a Git checkout." >&2
    exit 1
  else
    git clone https://github.com/daiksud/dotfiles.git "$HOME/.dotfiles"
  fi
  cd "$HOME/.dotfiles"
fi

# Preserve apps/fonts installed manually before Homebrew managed this machine.
if [[ -d /Applications/Ghostty.app ]] && ! brew list --cask ghostty >/dev/null 2>&1; then
  export HOMEBREW_BUNDLE_CASK_SKIP="${HOMEBREW_BUNDLE_CASK_SKIP:+$HOMEBREW_BUNDLE_CASK_SKIP }ghostty"
fi
if [[ -f "$HOME/Library/Fonts/MoralerspaceNeonHW-Regular.ttf" ]] && ! brew list --cask font-moralerspace-hw >/dev/null 2>&1; then
  export HOMEBREW_BUNDLE_CASK_SKIP="${HOMEBREW_BUNDLE_CASK_SKIP:+$HOMEBREW_BUNDLE_CASK_SKIP }font-moralerspace-hw"
fi

brew bundle --no-upgrade --file=homebrew/Brewfile
stow --no-folding --target="$HOME" editorconfig git ghostty herdr nvim rumdl sheldon starship zsh
apm install --global daiksud/agents --target codex,copilot
apm compile --global

if ! gh auth status >/dev/null 2>&1; then
  echo "Sign in to GitHub to finish CLI setup:"
  gh auth login </dev/tty
fi
gh extension install --force daiksud/gh-qw
gh extension install --force babarot/gh-infra

echo "Setup complete. Open Ghostty to start your configured environment."
