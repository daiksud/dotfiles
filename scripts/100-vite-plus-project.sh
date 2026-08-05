#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
VITE_PLUS_HOME="${VP_HOME:-${HOME}/.vite-plus}"

# shellcheck source=/dev/null
. "${VITE_PLUS_HOME}/env"

cd "${REPO_ROOT}"
vp install --frozen-lockfile
