#!/bin/bash

FILE=$(readlink -f "$0")
DIR=$(dirname "${FILE}")
DOTFILES_GITCONFIG="${DIR}/dotfiles/.gitconfig"
HOME_GITCONFIG="${HOME}/.gitconfig"

is_excluded_gitconfig_key() {
  local key="$1"
  [[ "${key}" = "user.name" || "${key}" = "user.email" ]]
}

non_user_gitconfig_snapshot() {
  local config_file="$1"
  git config -f "${config_file}" --list \
    | awk -F= '$1 != "user.name" && $1 != "user.email" { print }' \
    | LC_ALL=C sort
}

has_non_user_gitconfig_diff() {
  local left="$1"
  local right="$2"
  local left_tmp
  local right_tmp

  left_tmp=$(mktemp)
  right_tmp=$(mktemp)
  non_user_gitconfig_snapshot "${left}" > "${left_tmp}"
  non_user_gitconfig_snapshot "${right}" > "${right_tmp}"

  if cmp -s "${left_tmp}" "${right_tmp}"; then
    rm -f "${left_tmp}" "${right_tmp}"
    return 1
  fi

  rm -f "${left_tmp}" "${right_tmp}"
  return 0
}

sync_dotfiles_gitconfig_from_home() {
  local key
  local value

  while IFS= read -r key; do
    [[ -z "${key}" ]] && continue
    is_excluded_gitconfig_key "${key}" && continue

    if ! git config -f "${HOME_GITCONFIG}" --get-all "${key}" >/dev/null 2>&1; then
      git config -f "${DOTFILES_GITCONFIG}" --unset-all "${key}"
    fi
  done < <(git config -f "${DOTFILES_GITCONFIG}" --name-only --list | LC_ALL=C sort -u)

  while IFS= read -r key; do
    [[ -z "${key}" ]] && continue
    is_excluded_gitconfig_key "${key}" && continue

    while git config -f "${DOTFILES_GITCONFIG}" --get-all "${key}" >/dev/null 2>&1; do
      git config -f "${DOTFILES_GITCONFIG}" --unset-all "${key}"
    done

    while IFS= read -r value; do
      git config -f "${DOTFILES_GITCONFIG}" --add "${key}" "${value}"
    done < <(git config -f "${HOME_GITCONFIG}" --get-all "${key}")
  done < <(git config -f "${HOME_GITCONFIG}" --name-only --list | LC_ALL=C sort -u)
}

# Create symlinks for dotfiles
for src in "${DIR}"/dotfiles/.*; do
  # Skip if it's . or ..
  [ "${src}" = "${DIR}/dotfiles/." ] || [ "${src}" = "${DIR}/dotfiles/.." ] && continue

  name=$(basename "${src}")
  if [[ "${name}" = ".gitconfig" ]]; then
    continue
  fi

  dst="${HOME}/${name}"

  # Remove if it already exists
  if [[ -e "${dst}" || -L "${dst}" ]]; then
    echo "Removing existing ${dst}"
    rm -rf "${dst}"
  fi

  echo "Linking ${src} -> ${dst}"
  ln -s "${src}" "${dst}"
done

if [[ ! -e "${HOME_GITCONFIG}" && ! -L "${HOME_GITCONFIG}" ]]; then
  echo "Copying ${DOTFILES_GITCONFIG} -> ${HOME_GITCONFIG}"
  cp "${DOTFILES_GITCONFIG}" "${HOME_GITCONFIG}"
elif [[ -f "${HOME_GITCONFIG}" || -L "${HOME_GITCONFIG}" ]]; then
  if has_non_user_gitconfig_diff "${HOME_GITCONFIG}" "${DOTFILES_GITCONFIG}"; then
    echo "Syncing non-user keys from ${HOME_GITCONFIG} -> ${DOTFILES_GITCONFIG}"
    sync_dotfiles_gitconfig_from_home
  fi
fi

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
