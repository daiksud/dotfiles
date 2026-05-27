#!/bin/bash

FILE=$(readlink -f "$0")
DIR=$(dirname "${FILE}")

parse_links() {
  python3 -c "
import json, os, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for src, dst in data.get('links', {}).items():
    print(src + '\t' + dst.replace('~', os.path.expanduser('~')))
" "$1"
}

# If the parent directory of dst is a symlink, convert it to a real directory
# and migrate existing contents from the old symlink target.
ensure_real_parent_dir() {
  local dst="$1"
  local parent
  parent="$(dirname "${dst}")"

  if [[ -L "${parent}" ]]; then
    local target
    target="$(readlink "${parent}")"
    echo "Converting symlink ${parent} to real directory (was -> ${target})"
    rm "${parent}"
    mkdir -p "${parent}"
    if [[ -d "${target}" ]]; then
      for item in "${target}"/.[!.]* "${target}"/*; do
        [[ -e "${item}" || -L "${item}" ]] || continue
        local name
        name="$(basename "${item}")"
        if [[ ! -e "${parent}/${name}" && ! -L "${parent}/${name}" ]]; then
          echo "  Migrating ${item} -> ${parent}/${name}"
          mv "${item}" "${parent}/${name}"
        fi
      done
    fi
  else
    mkdir -p "${parent}"
  fi
}

MAP_FILE="${DIR}/install_map.json"

while IFS=$'\t' read -r src dst; do
  full_src="${DIR}/dotfiles/${src}"

  ensure_real_parent_dir "${dst}"

  if [[ -e "${dst}" || -L "${dst}" ]]; then
    echo "Removing existing ${dst}"
    rm -rf "${dst}"
  fi

  echo "Linking ${full_src} -> ${dst}"
  ln -s "${full_src}" "${dst}"
done < <(parse_links "${MAP_FILE}")

is_brew_dependent_100_script() {
  case "$(basename "$1")" in
  100-ghostty.sh | 100-lazyvim.sh | 100-sheldon.sh)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

run_script_collect_failure() {
  local script="$1"
  echo "Run ${script}"
  if ! /bin/bash "${script}"; then
    FAILED_SCRIPTS+=("${script}")
  fi
}

run_parallel_batch_collect_failure() {
  local max_jobs="$1"
  shift
  local -a pids=()
  local -a scripts=()
  local i
  local script

  for script in "$@"; do
    echo "Run ${script}"
    /bin/bash "${script}" &
    pids+=("$!")
    scripts+=("${script}")

    if [[ "${#pids[@]}" -ge "${max_jobs}" ]]; then
      for i in "${!pids[@]}"; do
        if ! wait "${pids[$i]}"; then
          FAILED_SCRIPTS+=("${scripts[$i]}")
        fi
      done
      pids=()
      scripts=()
    fi
  done

  for i in "${!pids[@]}"; do
    if ! wait "${pids[$i]}"; then
      FAILED_SCRIPTS+=("${scripts[$i]}")
    fi
  done
}

declare -a script_files=()
declare -a pre_100_scripts=()
declare -a brew_100_scripts=()
declare -a non_brew_100_scripts=()
declare -a FAILED_SCRIPTS=()

while IFS= read -r script; do
  script_files+=("${script}")
done < <(find "${DIR}/scripts" -type f -name '*.sh' | sort)

for script in "${script_files[@]}"; do
  case "$(basename "${script}")" in
  100-*)
    if is_brew_dependent_100_script "${script}"; then
      brew_100_scripts+=("${script}")
    else
      non_brew_100_scripts+=("${script}")
    fi
    ;;
  *)
    pre_100_scripts+=("${script}")
    ;;
  esac
done

for script in "${pre_100_scripts[@]}"; do
  run_script_collect_failure "${script}"
done

for script in "${brew_100_scripts[@]}"; do
  run_script_collect_failure "${script}"
done

parallel_jobs="${DOTFILES_PARALLEL_JOBS:-3}"
if ! [[ "${parallel_jobs}" =~ ^[1-9][0-9]*$ ]]; then
  parallel_jobs=3
fi
run_parallel_batch_collect_failure "${parallel_jobs}" "${non_brew_100_scripts[@]}"

# Generate ~/.ssh/allowed_signers for git SSH signature verification
ALLOWED_SIGNERS="${HOME}/.ssh/allowed_signers"
GIT_EMAIL=$(git config --global user.email 2>/dev/null)
SSH_PUBKEY="${HOME}/.ssh/id_ed25519.pub"
if [[ -n "${GIT_EMAIL}" && -f "${SSH_PUBKEY}" ]]; then
  echo "Generating ${ALLOWED_SIGNERS}"
  echo "${GIT_EMAIL} $(cat "${SSH_PUBKEY}")" > "${ALLOWED_SIGNERS}"
  chmod 600 "${ALLOWED_SIGNERS}"
fi

if [[ "${#FAILED_SCRIPTS[@]}" -gt 0 ]]; then
  echo "The following scripts failed:"
  for script in "${FAILED_SCRIPTS[@]}"; do
    echo "  - ${script}"
  done
  exit 1
fi
