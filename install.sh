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

find "${DIR}/scripts" -type f -name '*.sh' | sort | while IFS= read -r script; do
  echo "Run ${script}"
  /bin/bash "${script}"
done

# Generate ~/.ssh/allowed_signers for git SSH signature verification
ALLOWED_SIGNERS="${HOME}/.ssh/allowed_signers"
GIT_EMAIL=$(git config --global user.email 2>/dev/null)
SSH_PUBKEY="${HOME}/.ssh/id_ed25519.pub"
if [[ -n "${GIT_EMAIL}" && -f "${SSH_PUBKEY}" ]]; then
  echo "Generating ${ALLOWED_SIGNERS}"
  echo "${GIT_EMAIL} $(cat "${SSH_PUBKEY}")" > "${ALLOWED_SIGNERS}"
  chmod 600 "${ALLOWED_SIGNERS}"
fi
