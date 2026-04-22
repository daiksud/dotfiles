#!/bin/bash

if ! command -v gh >/dev/null 2>&1; then
  echo "gh command is required to install GitHub CLI extensions" >&2
  exit 1
fi

extensions=(
  "HikaruEgashira/gh-q"
)

for extension in "${extensions[@]}"; do
  if gh extension list | awk '{print $1}' | grep -qx "${extension}"; then
    continue
  fi

  gh extension install "${extension}"
done
