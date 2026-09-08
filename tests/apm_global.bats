#!/usr/bin/env bats

SCRIPT_SOURCE="${BATS_TEST_DIRNAME}/../scripts/100-apm.sh"

setup() {
  TEST_TMP="$(mktemp -d)"
  REPO_ROOT="${TEST_TMP}/repo"
  FAKE_HOME="${TEST_TMP}/home"
  FAKE_BIN="${TEST_TMP}/bin"
  COMMAND_LOG="${TEST_TMP}/commands.log"
  SCRIPT="${REPO_ROOT}/scripts/100-apm.sh"
  SOURCE_DIR="${REPO_ROOT}/dotfiles/apm"

  mkdir -p "${REPO_ROOT}/scripts" "${SOURCE_DIR}" "${FAKE_HOME}" "${FAKE_BIN}"
  cp "${SCRIPT_SOURCE}" "${SCRIPT}"
  printf '%s\n' 'name: dotfiles-global-apm' >"${SOURCE_DIR}/apm.yml"

  cat >"${FAKE_BIN}/apm" <<'EOF'
#!/bin/bash
printf 'apm %s\n' "$*" >>"${COMMAND_LOG}"
if [[ "$*" == "compile --global" ]]; then
  exit "${FAKE_APM_COMPILE_STATUS:-0}"
fi
exit "${FAKE_APM_STATUS:-0}"
EOF
  chmod +x "${FAKE_BIN}/apm"
}

teardown() {
  rm -rf "${TEST_TMP}"
}

invoke_apm_script() {
  env \
    HOME="${FAKE_HOME}" \
    COMMAND_LOG="${COMMAND_LOG}" \
    DOTFILES_APM_BIN="${FAKE_BIN}/apm" \
    FAKE_APM_STATUS="${FAKE_APM_STATUS:-0}" \
    FAKE_APM_COMPILE_STATUS="${FAKE_APM_COMPILE_STATUS:-0}" \
    /bin/bash "${SCRIPT}"
}

backup_count() {
  if [[ ! -d "${FAKE_HOME}/.apm/backups" ]]; then
    printf '0\n'
    return
  fi
  find "${FAKE_HOME}/.apm/backups" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' '
}

directory_mode() {
  if [[ "$(uname)" == "Darwin" ]]; then
    stat -f '%Lp' "$1"
  else
    stat -c '%a' "$1"
  fi
}

@test "copies the canonical manifest and installs global agent packages" {
  run invoke_apm_script

  [ "$status" -eq 0 ]
  [ -f "${FAKE_HOME}/.apm/apm.yml" ]
  [ ! -L "${FAKE_HOME}/.apm/apm.yml" ]
  cmp "${SOURCE_DIR}/apm.yml" "${FAKE_HOME}/.apm/apm.yml"
  grep -Fxq 'managed-by=daiksud/dotfiles' "${FAKE_HOME}/.apm/.dotfiles-apm-managed"
  grep -Fxq 'apm install --global' "${COMMAND_LOG}"
  grep -Fxq 'apm compile --global' "${COMMAND_LOG}"
  ! grep -Fxq 'apm compile --target codex' "${COMMAND_LOG}"
  [ "$(backup_count)" = "0" ]
}

@test "backs up unmanaged global configuration before replacing it" {
  mkdir -p "${FAKE_HOME}/.apm"
  printf '%s\n' 'name: existing-configuration' >"${FAKE_HOME}/.apm/apm.yml"
  printf '%s\n' 'existing-lockfile' >"${FAKE_HOME}/.apm/apm.lock.yaml"

  run invoke_apm_script

  [ "$status" -eq 0 ]
  backup_dir="$(find "${FAKE_HOME}/.apm/backups" -mindepth 1 -maxdepth 1 -type d -print -quit)"
  [ -n "${backup_dir}" ]
  [ "$(directory_mode "${backup_dir}")" = "700" ]
  grep -Fxq 'name: existing-configuration' "${backup_dir}/apm.yml"
  cmp "${SOURCE_DIR}/apm.yml" "${FAKE_HOME}/.apm/apm.yml"
  grep -Fxq 'existing-lockfile' "${FAKE_HOME}/.apm/apm.lock.yaml"
}

@test "restores canonical configuration without creating another backup" {
  mkdir -p "${FAKE_HOME}/.apm"
  printf '%s\n' 'name: existing-configuration' >"${FAKE_HOME}/.apm/apm.yml"

  run invoke_apm_script
  [ "$status" -eq 0 ]
  [ "$(backup_count)" = "1" ]

  printf '%s\n' 'local drift' >"${FAKE_HOME}/.apm/apm.yml"
  run invoke_apm_script

  [ "$status" -eq 0 ]
  [ "$(backup_count)" = "1" ]
  [ -f "${FAKE_HOME}/.apm/apm.yml" ]
  [ ! -L "${FAKE_HOME}/.apm/apm.yml" ]
  cmp "${SOURCE_DIR}/apm.yml" "${FAKE_HOME}/.apm/apm.yml"
}

@test "fails before modifying state when the manifest source is missing" {
  rm "${SOURCE_DIR}/apm.yml"

  run invoke_apm_script

  [ "$status" -ne 0 ]
  [[ "${output}" == *"APM manifest source is missing"* ]]
  [ ! -e "${FAKE_HOME}/.apm" ]
}

@test "rejects directory collisions without invoking APM" {
  mkdir -p "${FAKE_HOME}/.apm/apm.yml"

  run invoke_apm_script

  [ "$status" -ne 0 ]
  [[ "${output}" == *"APM configuration path must not be a directory"* ]]
  [ ! -e "${COMMAND_LOG}" ]
}

@test "propagates a failed global APM install" {
  FAKE_APM_STATUS=27

  run invoke_apm_script

  [ "$status" -eq 27 ]
  grep -Fxq 'apm install --global' "${COMMAND_LOG}"
}

@test "propagates a failed global APM compilation" {
  FAKE_APM_COMPILE_STATUS=28

  run invoke_apm_script

  [ "$status" -eq 28 ]
  [ -f "${FAKE_HOME}/.apm/apm.yml" ]
  [ ! -L "${FAKE_HOME}/.apm/apm.yml" ]
  grep -Fxq 'apm install --global' "${COMMAND_LOG}"
  grep -Fxq 'apm compile --global' "${COMMAND_LOG}"
}
