#!/bin/bash

FILE=$(readlink -f "$0")
DIR=$(dirname "${FILE}")

export HOMEBREW_NO_ASK=1

parse_links() {
  python3 -c "
import json, os, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
links = data.get('links', {})
if not isinstance(links, dict):
    raise TypeError('links must be an object')
for src, destinations in links.items():
    if isinstance(destinations, str):
        destinations = [destinations]
    elif not isinstance(destinations, list) or not all(isinstance(dst, str) for dst in destinations):
        raise TypeError('each links value must be a string or an array of strings')
    for dst in destinations:
        print(src + '\t' + os.path.expanduser(dst))
" "$1"
}

MAP_FILE="${DIR}/install_map.json"
if ! PARSED_LINKS="$(parse_links "${MAP_FILE}")"; then
  echo "Cannot parse links from ${MAP_FILE}" >&2
  exit 1
fi

if [[ -n "${PARSED_LINKS}" ]]; then
  while IFS=$'\t' read -r src dst; do
    full_src="${DIR}/dotfiles/${src}"
    mkdir -p "$(dirname "${dst}")"

    if [[ -e "${dst}" || -L "${dst}" ]]; then
      echo "Removing existing ${dst}"
      rm -rf "${dst}" || exit 1
    fi

    echo "Linking ${full_src} -> ${dst}"
    ln -s "${full_src}" "${dst}" || exit 1
  done <<<"${PARSED_LINKS}"
fi

is_brew_dependent_100_script() {
  case "$(basename "$1")" in
  100-apm.sh | 100-ghostty.sh | 100-lazyvim.sh | 100-sheldon.sh)
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
