#!/bin/bash

set -euo pipefail

curl -fsSL https://vite.plus | CI=true VP_NODE_MANAGER=yes /bin/bash

VITE_PLUS_HOME="${VP_HOME:-${HOME}/.vite-plus}"
# shellcheck source=/dev/null
. "${VITE_PLUS_HOME}/env"

vp env on
vp env default lts
vp install -g bun@latest --node lts

vp --version
node --version
bun --version
