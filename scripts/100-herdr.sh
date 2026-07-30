#!/bin/bash

# Keep the herdr server resident across reboots so panes and agents survive
# terminal restarts. `brew services` manages this via launchd, which is
# macOS-only; on Linux (e.g. Codespaces) herdr is simply run on demand.
if [[ "$(uname)" != "Darwin" ]]; then
  exit 0
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

brew services start herdr
