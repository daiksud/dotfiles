#!/bin/bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo_root="$(cd -- "${script_dir}/.." && pwd -P)"
source_dir="${repo_root}/dotfiles/apm"
source_manifest="${source_dir}/apm.yml"

if [[ -z "${HOME:-}" ]]; then
  echo "HOME must be set to install the global APM configuration" >&2
  exit 1
fi

case "$(uname -s)" in
Darwin)
  default_brew_bin="/opt/homebrew/bin/brew"
  ;;
Linux)
  default_brew_bin="/home/linuxbrew/.linuxbrew/bin/brew"
  ;;
*)
  echo "Unsupported OS: $(uname -s)" >&2
  exit 1
  ;;
esac

brew_bin="${DOTFILES_BREW_BIN:-${default_brew_bin}}"
apm_bin="${DOTFILES_APM_BIN:-$(dirname "${brew_bin}")/apm}"

if [[ ! -x "${apm_bin}" ]]; then
  echo "apm command is required at ${apm_bin}; ensure Brewfile installation completed" >&2
  exit 1
fi

if [[ ! -f "${source_manifest}" ]]; then
  echo "APM manifest source is missing: ${source_manifest}" >&2
  exit 1
fi

apm_home="${HOME}/.apm"
manifest="${apm_home}/apm.yml"
marker="${apm_home}/.dotfiles-apm-managed"
backup_root="${apm_home}/backups"

if [[ -L "${apm_home}" || ( -e "${apm_home}" && ! -d "${apm_home}" ) ]]; then
  echo "APM state directory must be a real directory: ${apm_home}" >&2
  exit 1
fi

mkdir -p "${apm_home}"

if [[ -d "${manifest}" && ! -L "${manifest}" ]]; then
  echo "APM configuration path must not be a directory: ${manifest}" >&2
  exit 1
fi

if [[ -L "${backup_root}" || ( -e "${backup_root}" && ! -d "${backup_root}" ) ]]; then
  echo "APM backup path must be a real directory: ${backup_root}" >&2
  exit 1
fi

if [[ -L "${marker}" || ( -e "${marker}" && ! -f "${marker}" ) ]]; then
  echo "APM management marker must be a regular file: ${marker}" >&2
  exit 1
fi

is_managed=0
if [[ -f "${marker}" ]]; then
  if ! grep -qx 'managed-by=daiksud/dotfiles' "${marker}"; then
    echo "APM management marker is not recognized: ${marker}" >&2
    exit 1
  fi
  is_managed=1
fi

if [[ "${is_managed}" -eq 0 ]]; then
  existing_files=()
  if [[ -e "${manifest}" || -L "${manifest}" ]]; then
    existing_files+=("${manifest}")
  fi

  if [[ "${#existing_files[@]}" -gt 0 ]]; then
    (umask 077 && mkdir -p "${backup_root}")
    if ! backup_dir="$(umask 077 && mktemp -d "${backup_root}/dotfiles-apm.XXXXXX")"; then
      echo "Could not create APM configuration backup directory" >&2
      exit 1
    fi
    chmod 700 "${backup_dir}"

    for destination in "${existing_files[@]}"; do
      cp -pP "${destination}" "${backup_dir}/$(basename "${destination}")"
    done

    echo "Backed up existing APM configuration to ${backup_dir}"
  fi
fi

if [[ -L "${manifest}" ]]; then
  rm -f "${manifest}"
fi
cp -p "${source_manifest}" "${manifest}"

if [[ "${is_managed}" -eq 0 ]]; then
  (umask 077 && printf '%s\n' 'managed-by=daiksud/dotfiles' >"${marker}")
fi

echo "Installing global APM configuration"
"${apm_bin}" install --global

compile_global_apm() {
  local compile_status

  if ! cp -p "${source_manifest}" "${manifest}"; then
    echo "Could not prepare APM manifest for compilation" >&2
    return 1
  fi

  if "${apm_bin}" compile --global; then
    compile_status=0
  else
    compile_status=$?
  fi

  return "${compile_status}"
}

compile_global_apm
