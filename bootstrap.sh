#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
  echo "This installer requires Apple Silicon macOS." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  if [[ -f "${BASH_SOURCE[0]:-}" && -f "$(dirname "${BASH_SOURCE[0]:-}")/homebrew/install.sh" ]]; then
    bash "$(dirname "${BASH_SOURCE[0]:-}")/homebrew/install.sh" --bootstrap-only
  else
    curl -fsSL https://raw.githubusercontent.com/daiksud/dotfiles/main/homebrew/install.sh | bash -s -- --bootstrap-only
  fi
fi
brew_bin="$(command -v brew || true)"
if [[ -z "$brew_bin" ]]; then
  brew_bin=/opt/homebrew/bin/brew
fi
if [[ ! -x "$brew_bin" ]]; then
  echo "Homebrew installation failed." >&2
  exit 1
fi
eval "$("$brew_bin" shellenv)"

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

./homebrew/install.sh
./ghostty/install.sh
./fonts/install.sh
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
