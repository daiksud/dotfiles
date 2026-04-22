#!/bin/bash

os="$(uname -s)"

if [[ "${os}" == "Darwin" ]]; then
  echo "Do nothing on macOS"
  exit 0
fi

if [[ -r /etc/os-release ]]; then
  . /etc/os-release
fi

if [[ "${os}" != "Linux" || "${ID:-}" != "ubuntu" ]]; then
  echo "Unsupported OS: ${os}${ID:+ (${ID})}" >&2
  exit 1
fi

# Set timezone to Asia/Tokyo
sudo cp -f /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Set default shell to zsh
sudo chsh "$(id -un)" --shell "/usr/bin/zsh"

sudo apt-get update
sudo apt-get install -y build-essential git
