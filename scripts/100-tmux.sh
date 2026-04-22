#!/bin/bash

TPM_ROOT="${HOME}/.tmux/plugins"
TPM_DIR="${TPM_ROOT}/tpm"

if [[ ! -d "${TPM_DIR}" ]]; then
  git clone --depth=1 https://github.com/tmux-plugins/tpm "${TPM_DIR}"
fi

tmux start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH "${TPM_ROOT}/"
"${TPM_DIR}/bin/install_plugins"
