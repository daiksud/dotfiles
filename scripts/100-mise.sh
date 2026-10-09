#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if [[ -L ~/.config/mise ]]; then
  rm ~/.config/mise
fi
mkdir -p ~/.config/mise
mise settings set github.credential_command "gh auth token"
mise install
mise exec -- bun install --frozen-lockfile
