#!/usr/bin/env bash

for brew_prefix in /opt/homebrew/bin /home/linuxbrew/.linuxbrew/bin; do
  [[ -d "$brew_prefix" ]] && PATH="$brew_prefix:$PATH"
done
export PATH

# Get session_id from tmux directly (display-popup doesn't expand #{} in its command arg)
session_id="$(tmux display-message -p '#{session_id}')"
url_file="/tmp/tmux-urls-${session_id}.txt"

if [[ ! -s "$url_file" ]]; then
  echo "No URLs found."
  read -r -s -n1
  exit 0
fi

url="$(fzf --reverse --height=100% < "$url_file")" || exit 0

if [[ -n "$url" ]]; then
  if command -v open >/dev/null 2>&1; then
    open "$url"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url"
  fi
fi
