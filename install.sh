#!/bin/bash

FILE=$(readlink -f "$0")
DIR=$(dirname "${FILE}")

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

parse_skill_targets() {
  python3 -c "
import json, os, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
targets = data.get('skill_targets', [])
if not isinstance(targets, list) or not all(isinstance(target, str) for target in targets):
    raise TypeError('skill_targets must be an array of strings')
for target in targets:
    print(os.path.expanduser(target))
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
    local target_path
    local resolved_target
    if ! target="$(readlink "${parent}")"; then
      echo "Cannot read symlink target for ${parent}" >&2
      return 1
    fi

    case "${target}" in
    /*) target_path="${target}" ;;
    *) target_path="$(dirname "${parent}")/${target}" ;;
    esac

    # Resolve and validate the target before unlinking the parent. Relative
    # symlink targets are interpreted from the symlink's directory, not from
    # the installer's current working directory.
    if ! resolved_target="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "${target_path}")"; then
      echo "Cannot resolve symlink target ${target} for ${parent}" >&2
      return 1
    fi
    if [[ ! -d "${resolved_target}" ]]; then
      echo "Cannot convert symlink ${parent}: target ${target} is not an existing directory" >&2
      return 1
    fi

    echo "Converting symlink ${parent} to real directory (was -> ${target})"
    rm "${parent}" || return 1
    mkdir -p "${parent}" || return 1
    for item in \
      "${resolved_target}"/.[!.]* \
      "${resolved_target}"/..?* \
      "${resolved_target}"/*; do
      [[ -e "${item}" || -L "${item}" ]] || continue
      local name
      name="$(basename "${item}")"
      if [[ ! -e "${parent}/${name}" && ! -L "${parent}/${name}" ]]; then
        echo "  Migrating ${item} -> ${parent}/${name}"
        mv "${item}" "${parent}/${name}" || return 1
      fi
    done
  else
    mkdir -p "${parent}"
  fi
}

# Copilot, Codex, and Claude may keep their complete configuration roots in a
# synced or relocated directory. Preserve those root links instead of applying
# the legacy parent-directory migration used for ordinary dotfile targets.
ensure_link_parent_dir() {
  local dst="$1"
  local home_root
  local parent
  home_root="${HOME%/}"
  [[ -n "${home_root}" ]] || home_root="/"
  parent="$(dirname "${dst}")"

  case "${parent}" in
  "${home_root%/}/.copilot" | "${home_root%/}/.codex" | "${home_root%/}/.claude")
    if [[ -L "${parent}" ]]; then
      if [[ ! -d "${parent}" ]]; then
        echo "Cannot use symlinked agent config directory ${parent}: target is not an existing directory" >&2
        return 1
      fi
      return 0
    fi
    ;;
  esac

  ensure_real_parent_dir "${dst}"
}

# Previous versions linked the entire canonical skills directory into Copilot.
# Remove only that exact legacy link. In particular, do not run the generic
# parent-directory migration for it: doing so would move the canonical sources.
cleanup_legacy_copilot_skills() {
  local configured_targets="$1"
  local legacy_path="${HOME}/.copilot/skills"
  local canonical_skills="${DIR}/dotfiles/skills"

  [[ -L "${legacy_path}" ]] || return 0

  local resolved_legacy
  local resolved_canonical
  local resolved_target
  local target_root
  if ! resolved_legacy="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "${legacy_path}")"; then
    echo "Cannot resolve legacy skills link ${legacy_path}" >&2
    return 1
  fi
  if ! resolved_canonical="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "${canonical_skills}")"; then
    echo "Cannot resolve canonical skills directory ${canonical_skills}" >&2
    return 1
  fi

  if [[ "${resolved_legacy}" == "${resolved_canonical}" ]]; then
    # A whole-directory replacement link that resolves to the canonical source
    # may itself traverse the legacy path. Retaining the same canonical
    # Copilot link is safer than making a configured discovery root dangling.
    while IFS= read -r target_root; do
      [[ -n "${target_root}" && -L "${target_root}" ]] || continue
      if ! resolved_target="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "${target_root}")"; then
        echo "Cannot resolve skill target root ${target_root}" >&2
        return 1
      fi
      if [[ "${resolved_target}" == "${resolved_canonical}" ]]; then
        echo "Keeping legacy skills link ${legacy_path}: ${target_root} is a whole-directory alias to the canonical skills"
        return 0
      fi
    done <<<"${configured_targets}"

    echo "Removing legacy skills link ${legacy_path}"
    rm "${legacy_path}"
  fi
}

link_skills_into() {
  local target_root="$1"
  local canonical_skills="${DIR}/dotfiles/skills"
  local skill_src
  local skill_name
  local dst
  local resolved_dst
  local resolved_skill

  mkdir -p "${target_root}" || return 1

  # Include hidden source directories if they are valid skills. Unmatched
  # globs are discarded by the directory/SKILL.md checks.
  for skill_src in \
    "${canonical_skills}"/* \
    "${canonical_skills}"/.[!.]* \
    "${canonical_skills}"/..?*; do
    [[ -d "${skill_src}" && -f "${skill_src}/SKILL.md" ]] || continue

    skill_name="$(basename "${skill_src}")"
    dst="${target_root}/${skill_name}"

    # A target root may itself already be a legacy whole-directory symlink.
    # In that case dst resolves to the canonical source directory; deleting it
    # would delete the source rather than a destination entry.
    if [[ -e "${dst}" ]]; then
      if ! resolved_dst="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "${dst}")"; then
        echo "Cannot resolve existing skill destination ${dst}" >&2
        return 1
      fi
      if ! resolved_skill="$(python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "${skill_src}")"; then
        echo "Cannot resolve canonical skill directory ${skill_src}" >&2
        return 1
      fi
      if [[ "${resolved_dst}" == "${resolved_skill}" ]]; then
        echo "Skill ${skill_name} is already available through ${target_root}"
        continue
      fi
    fi

    if [[ -e "${dst}" || -L "${dst}" ]]; then
      echo "Removing existing ${dst}"
      rm -rf "${dst}" || return 1
    fi

    echo "Linking ${skill_src} -> ${dst}"
    ln -s "${skill_src}" "${dst}" || return 1
  done
}

MAP_FILE="${DIR}/install_map.json"

PARSED_LINKS=""
PARSED_SKILL_TARGETS=""
if ! PARSED_LINKS="$(parse_links "${MAP_FILE}")"; then
  echo "Cannot parse links from ${MAP_FILE}" >&2
  exit 1
fi
if ! PARSED_SKILL_TARGETS="$(parse_skill_targets "${MAP_FILE}")"; then
  echo "Cannot parse skill targets from ${MAP_FILE}" >&2
  exit 1
fi

if [[ -n "${PARSED_LINKS}" ]]; then
  while IFS=$'\t' read -r src dst; do
    full_src="${DIR}/dotfiles/${src}"

    if ! ensure_link_parent_dir "${dst}"; then
      exit 1
    fi

    if [[ -e "${dst}" || -L "${dst}" ]]; then
      echo "Removing existing ${dst}"
      rm -rf "${dst}" || exit 1
    fi

    echo "Linking ${full_src} -> ${dst}"
    ln -s "${full_src}" "${dst}" || exit 1
  done <<<"${PARSED_LINKS}"
fi

if [[ -n "${PARSED_SKILL_TARGETS}" ]]; then
  while IFS= read -r target_root; do
    if ! link_skills_into "${target_root}"; then
      exit 1
    fi
  done <<<"${PARSED_SKILL_TARGETS}"

  # Keep the old Copilot discovery path available until every replacement link
  # has been installed successfully. An empty target list provides no
  # replacement discovery path, so it must not trigger legacy cleanup.
  if ! cleanup_legacy_copilot_skills "${PARSED_SKILL_TARGETS}"; then
    exit 1
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
