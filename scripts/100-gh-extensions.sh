#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh command is required to install GitHub CLI extensions" >&2
  exit 1
fi

extensions=(
  "daiksud/gh-qw"
  "babarot/gh-infra"
)

for extension in "${extensions[@]}"; do
  # `gh extension list` reports the local command name (for example "gh qw"),
  # not the "<owner>/<repo>" spec, in its first tab-separated column. Compare
  # against that derived name so both a repo-installed and a locally
  # symlinked extension are detected; a plain awk/grep match on "${extension}"
  # never matched anything.
  repo_name="${extension#*/}"
  command_name="gh ${repo_name#gh-}"

  if gh extension list | cut -f1 | grep -qx "${command_name}"; then
    continue
  fi

  gh extension install "${extension}"
done

pkgs=(
  fd
)
brew install --quiet "${pkgs[@]}"
