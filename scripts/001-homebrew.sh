#!/bin/bash

if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ] && [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

case "$(uname -s)" in
Darwin)
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ;;
Linux)
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  ;;
*)
  echo "Unsupported OS: $(uname -s)" >&2
  exit 1
  ;;
esac

brew install --quiet gcc
brew upgrade --quiet
