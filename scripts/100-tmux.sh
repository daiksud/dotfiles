#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

TPM_ROOT="${HOME}/.tmux/plugins"
TPM_DIR="${TPM_ROOT}/tpm"

if [[ ! -d "${TPM_DIR}" ]]; then
  git clone --depth=1 https://github.com/tmux-plugins/tpm "${TPM_DIR}"
fi

tmux start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH "${TPM_ROOT}/"
"${TPM_DIR}/bin/install_plugins"

pkgs=(
  bash
  bc
  coreutils
  gawk
  gh
  git
  jq
)
brew install --quiet "${pkgs[@]}"

if [[ "$(uname)" == "Darwin" ]]; then
  brew install --quiet glab gsed nowplaying-cli font-noto-sans-symbols-2
else
  brew install --quiet playerctl
fi
