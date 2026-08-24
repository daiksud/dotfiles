#!/usr/bin/env bats
# Behavior tests for scripts/100-herdr.sh.
#
# The real script uses Homebrew and launchd on macOS. These tests replace the
# external commands with stateful stubs so service handoff behavior can be
# checked without stopping the real Herdr session.

SCRIPT="${BATS_TEST_DIRNAME}/../scripts/100-herdr.sh"

setup() {
  TEST_TMP="$(mktemp -d)"
  FAKE_BIN="${TEST_TMP}/bin"
  COMMAND_LOG="${TEST_TMP}/commands.log"
  BREW_SERVICE_FILE="${TEST_TMP}/brew-services.json"
  HERDR_STATUS_FILE="${TEST_TMP}/herdr-status.json"
  HERDR_AFTER_START_FILE="${TEST_TMP}/herdr-after-start.json"
  SERVICE_STARTED_FILE="${TEST_TMP}/service-started"
  BREW_LIST_COUNT_FILE="${TEST_TMP}/brew-list-count"
  SERVICE_SNAPSHOT_FILE="${TEST_TMP}/service-snapshot-captured"
  RELEASE_SNAPSHOT_FILE="${TEST_TMP}/release-service-snapshot"
  LOCK_FILE="${TEST_TMP}/herdr-service.lock"
  LOCK_WAITING_FILE="${TEST_TMP}/lock-waiting"
  PYTHON_BIN="$(command -v python3)"

  mkdir -p "${FAKE_BIN}"
  printf '0\n' >"${BREW_LIST_COUNT_FILE}"

  cat >"${FAKE_BIN}/uname" <<'EOF'
#!/bin/sh
printf '%s\n' "${FAKE_UNAME:-Darwin}"
EOF

  cat >"${FAKE_BIN}/brew" <<'EOF'
#!/bin/bash
printf 'brew %s\n' "$*" >>"${COMMAND_LOG}"

set_service_status() {
  printf '[{"name":"herdr","status":"%s","user":"test","file":"%s","exit_code":0}]\n' \
    "$1" "${HOME}/Library/LaunchAgents/homebrew.mxcl.herdr.plist" >"${BREW_SERVICE_FILE}"
}

case "$*" in
shellenv)
  printf 'export PATH="%s:$PATH"\n' "$(dirname "$0")"
  ;;
"services list --json")
  list_count=0
  if [[ -f "${BREW_LIST_COUNT_FILE}" ]]; then
    IFS= read -r list_count <"${BREW_LIST_COUNT_FILE}"
  fi
  list_count=$((list_count + 1))
  printf '%s\n' "${list_count}" >"${BREW_LIST_COUNT_FILE}"

  if [[ "${BREW_LIST_FAIL_AT:-0}" == "${list_count}" ]]; then
    echo "fake brew list failure" >&2
    exit 1
  fi

  if [[ "${PAUSE_AFTER_SERVICE_SNAPSHOT:-0}" == "1" && "${list_count}" == "2" ]]; then
    cat "${BREW_SERVICE_FILE}"
    touch "${SERVICE_SNAPSHOT_FILE}"
    while [[ ! -f "${RELEASE_SNAPSHOT_FILE}" ]]; do
      sleep 0.01
    done
  else
    cat "${BREW_SERVICE_FILE}"
  fi
  ;;
"services stop herdr")
  if [[ "${BREW_STOP_FAIL:-0}" == "1" ]]; then
    echo "fake brew stop failure" >&2
    exit 1
  fi
  if [[ "${RECOVER_DURING_STOP:-0}" == "1" ]]; then
    touch "${SERVICE_STARTED_FILE}"
    set_service_status started
  else
    set_service_status stopped
  fi
  ;;
"services start herdr")
  if [[ "${BREW_START_FAIL:-0}" == "1" ]]; then
    echo "fake brew start failure" >&2
    exit 1
  fi
  touch "${SERVICE_STARTED_FILE}"
  set_service_status started
  ;;
*)
  echo "unexpected brew command: $*" >&2
  exit 1
  ;;
esac
EOF

  cat >"${FAKE_BIN}/herdr" <<'EOF'
#!/bin/bash
printf 'herdr %s\n' "$*" >>"${COMMAND_LOG}"
printf 'herdr selectors socket=%s session=%s\n' \
  "${HERDR_SOCKET_PATH-unset}" "${HERDR_SESSION-unset}" >>"${COMMAND_LOG}"

case "$*" in
"status server --json")
  if [[ -f "${SERVICE_STARTED_FILE}" ]]; then
    cat "${HERDR_AFTER_START_FILE}"
  else
    cat "${HERDR_STATUS_FILE}"
  fi
  ;;
"server stop")
  if [[ "${HERDR_STOP_FAIL:-0}" == "1" ]]; then
    echo "fake herdr stop failure" >&2
    exit 1
  fi
  cat >"${HERDR_STATUS_FILE}" <<'JSON'
{"status":"not_running","running":false,"version":null,"protocol":null,"capabilities":null,"compatible":null,"socket":"/tmp/herdr.sock","session":null,"restart_needed":false}
JSON
  ;;
*)
  echo "unexpected herdr command: $*" >&2
  exit 1
  ;;
esac
EOF

  cat >"${FAKE_BIN}/lockf" <<'EOF'
#!/bin/bash
if [[ "$1" != "-k" || "$#" -lt 4 ]]; then
  echo "unexpected lockf arguments: $*" >&2
  exit 1
fi

lock_file="$2"
shift 2
lock_dir="${lock_file}.held"

while ! mkdir "${lock_dir}" 2>/dev/null; do
  touch "${LOCK_WAITING_FILE}"
  sleep 0.01
done

release_lock() {
  rmdir "${lock_dir}" 2>/dev/null || true
}
trap release_lock EXIT

printf 'lockf acquired\n' >>"${COMMAND_LOG}"
"$@"
EOF

  chmod +x "${FAKE_BIN}/uname" "${FAKE_BIN}/brew" "${FAKE_BIN}/herdr" "${FAKE_BIN}/lockf"
}

teardown() {
  rm -rf "${TEST_TMP}"
}

write_service_list() {
  printf '%s\n' "$1" >"${BREW_SERVICE_FILE}"
}

write_herdr_status() {
  printf '%s\n' "$1" >"${HERDR_STATUS_FILE}"
}

assert_command_not_logged() {
  if grep -Fxq "$1" "${COMMAND_LOG}"; then
    echo "Unexpected command in log: $1" >&2
    return 1
  fi
}

assert_log_not_contains() {
  if grep -Fq "$1" "${COMMAND_LOG}"; then
    echo "Unexpected text in command log: $1" >&2
    return 1
  fi
}

wait_for_file() {
  local path="$1"
  local attempt

  for ((attempt = 1; attempt <= 200; attempt++)); do
    [[ -e "${path}" ]] && return 0
    sleep 0.01
  done
  return 1
}

invoke_herdr_script() {
  env \
    PATH="${FAKE_BIN}:/usr/bin:/bin" \
    FAKE_UNAME="${FAKE_UNAME:-Darwin}" \
    COMMAND_LOG="${COMMAND_LOG}" \
    BREW_SERVICE_FILE="${BREW_SERVICE_FILE}" \
    HERDR_STATUS_FILE="${HERDR_STATUS_FILE}" \
    HERDR_AFTER_START_FILE="${HERDR_AFTER_START_FILE}" \
    SERVICE_STARTED_FILE="${SERVICE_STARTED_FILE}" \
    BREW_LIST_COUNT_FILE="${BREW_LIST_COUNT_FILE}" \
    SERVICE_SNAPSHOT_FILE="${SERVICE_SNAPSHOT_FILE}" \
    RELEASE_SNAPSHOT_FILE="${RELEASE_SNAPSHOT_FILE}" \
    LOCK_WAITING_FILE="${LOCK_WAITING_FILE}" \
    DOTFILES_BREW_BIN="${FAKE_BIN}/brew" \
    DOTFILES_HERDR_BIN="${FAKE_BIN}/herdr" \
    DOTFILES_LOCKF_BIN="${FAKE_BIN}/lockf" \
    DOTFILES_HERDR_LOCK_FILE="${LOCK_FILE}" \
    DOTFILES_PYTHON_BIN="${PYTHON_BIN}" \
    DOTFILES_HERDR_WAIT_ATTEMPTS=1 \
    DOTFILES_HERDR_WAIT_SECONDS=0 \
    BREW_STOP_FAIL="${BREW_STOP_FAIL:-0}" \
    BREW_START_FAIL="${BREW_START_FAIL:-0}" \
    BREW_LIST_FAIL_AT="${BREW_LIST_FAIL_AT:-0}" \
    RECOVER_DURING_STOP="${RECOVER_DURING_STOP:-0}" \
    PAUSE_AFTER_SERVICE_SNAPSHOT="${PAUSE_AFTER_SERVICE_SNAPSHOT:-0}" \
    HERDR_STOP_FAIL="${HERDR_STOP_FAIL:-0}" \
    HERDR_ENV="${TEST_HERDR_ENV:-0}" \
    HERDR_SOCKET_PATH="${TEST_HERDR_SOCKET_PATH:-}" \
    HERDR_SESSION="${TEST_HERDR_SESSION:-}" \
    "${SCRIPT}"
}

run_herdr_script() {
  run invoke_herdr_script
}

healthy_herdr_status='{"status":"running","running":true,"version":"0.8.2","protocol":20,"capabilities":{"live_handoff":true},"compatible":true,"socket":"/tmp/herdr.sock","session":null,"restart_needed":false}'
compatible_upgrade_status='{"status":"running","running":true,"version":"0.8.1","protocol":20,"capabilities":{"live_handoff":true},"compatible":true,"socket":"/tmp/herdr.sock","session":null,"restart_needed":true}'
old_herdr_status='{"status":"running","running":true,"version":"0.8.0","protocol":19,"capabilities":{"live_handoff":true},"compatible":false,"socket":"/tmp/herdr.sock","session":null,"restart_needed":true}'
not_running_herdr_status='{"status":"not_running","running":false,"version":null,"protocol":null,"capabilities":null,"compatible":null,"socket":"/tmp/herdr.sock","session":null,"restart_needed":false}'
started_service='[{"name":"herdr","status":"started","user":"test","file":"/tmp/homebrew.mxcl.herdr.plist","exit_code":0}]'
error_service='[{"name":"herdr","status":"error","user":"test","file":"/tmp/homebrew.mxcl.herdr.plist","exit_code":1}]'
missing_service='[]'

@test "is a no-op outside macOS" {
  FAKE_UNAME=Linux
  run_herdr_script

  [ "$status" -eq 0 ]
  [ ! -e "${COMMAND_LOG}" ]
}

@test "starts a missing service and verifies the new server" {
  write_service_list "${missing_service}"
  write_herdr_status "${not_running_herdr_status}"
  printf '%s\n' "${healthy_herdr_status}" >"${HERDR_AFTER_START_FILE}"

  run_herdr_script

  [ "$status" -eq 0 ]
  grep -Fxq 'brew services start herdr' "${COMMAND_LOG}"
  assert_command_not_logged 'brew services stop herdr'
  [[ "$output" == *"Herdr service is running"* ]]
}

@test "preserves a healthy managed service" {
  write_service_list "${started_service}"
  write_herdr_status "${healthy_herdr_status}"

  run_herdr_script

  [ "$status" -eq 0 ]
  assert_command_not_logged 'brew services start herdr'
  assert_command_not_logged 'brew services stop herdr'
  [[ "$output" == *"already healthy"* ]]
}

@test "preserves a compatible managed service after a version-only upgrade" {
  write_service_list "${started_service}"
  write_herdr_status "${compatible_upgrade_status}"
  printf '%s\n' "${healthy_herdr_status}" >"${HERDR_AFTER_START_FILE}"

  run_herdr_script

  [ "$status" -eq 0 ]
  assert_command_not_logged 'brew services start herdr'
  assert_command_not_logged 'brew services stop herdr'
  assert_command_not_logged 'herdr server stop'
  [[ "$output" == *"already healthy"* ]]
}

@test "targets the Homebrew-managed default session during a handoff" {
  write_service_list "${error_service}"
  write_herdr_status "${old_herdr_status}"
  printf '%s\n' "${healthy_herdr_status}" >"${HERDR_AFTER_START_FILE}"
  TEST_HERDR_SOCKET_PATH=/tmp/named-herdr.sock
  TEST_HERDR_SESSION=named

  run_herdr_script

  [ "$status" -eq 0 ]
  grep -Fxq 'herdr selectors socket=unset session=unset' "${COMMAND_LOG}"
  assert_log_not_contains 'herdr selectors socket=/tmp/named-herdr.sock'
  assert_log_not_contains 'session=named'
}

@test "refuses a destructive handoff from a Herdr-managed pane" {
  write_service_list "${error_service}"
  write_herdr_status "${old_herdr_status}"
  printf '%s\n' "${healthy_herdr_status}" >"${HERDR_AFTER_START_FILE}"
  TEST_HERDR_ENV=1

  run_herdr_script

  [ "$status" -eq 1 ]
  assert_command_not_logged 'brew services stop herdr'
  assert_command_not_logged 'brew services start herdr'
  assert_command_not_logged 'herdr server stop'
  [[ "$output" == *"plain shell"* ]]
}

@test "stops an incompatible server before starting the current service" {
  write_service_list "${error_service}"
  write_herdr_status "${old_herdr_status}"
  printf '%s\n' "${healthy_herdr_status}" >"${HERDR_AFTER_START_FILE}"

  run_herdr_script

  [ "$status" -eq 0 ]
  stop_line="$(grep -n '^brew services stop herdr$' "${COMMAND_LOG}" | cut -d: -f1)"
  server_stop_line="$(grep -n '^herdr server stop$' "${COMMAND_LOG}" | cut -d: -f1)"
  start_line="$(grep -n '^brew services start herdr$' "${COMMAND_LOG}" | cut -d: -f1)"
  [ "${stop_line}" -lt "${server_stop_line}" ]
  [ "${server_stop_line}" -lt "${start_line}" ]
  [[ "$output" == *"will exit"* ]]
  [[ "$output" == *"Herdr service is running"* ]]
}

@test "preserves a compatible service recovered by another process" {
  write_service_list "${error_service}"
  write_herdr_status "${old_herdr_status}"
  printf '%s\n' "${healthy_herdr_status}" >"${HERDR_AFTER_START_FILE}"
  RECOVER_DURING_STOP=1

  run_herdr_script

  [ "$status" -eq 0 ]
  grep -Fxq 'brew services stop herdr' "${COMMAND_LOG}"
  assert_command_not_logged 'herdr server stop'
  assert_command_not_logged 'brew services start herdr'
  [[ "$output" == *"became healthy during handoff"* ]]
}

@test "preserves a compatible service recovered while its server was initially down" {
  write_service_list "${error_service}"
  write_herdr_status "${not_running_herdr_status}"
  printf '%s\n' "${healthy_herdr_status}" >"${HERDR_AFTER_START_FILE}"
  RECOVER_DURING_STOP=1

  run_herdr_script

  [ "$status" -eq 0 ]
  grep -Fxq 'brew services stop herdr' "${COMMAND_LOG}"
  assert_command_not_logged 'herdr server stop'
  assert_command_not_logged 'brew services start herdr'
  [[ "$output" == *"became healthy during handoff"* ]]
}

@test "serializes concurrent handoffs across the destructive decision" {
  local first_pid
  local second_pid
  local first_status=0
  local second_status=0
  local snapshot_seen=0
  local second_waited=0

  write_service_list "${error_service}"
  write_herdr_status "${old_herdr_status}"
  printf '%s\n' "${healthy_herdr_status}" >"${HERDR_AFTER_START_FILE}"
  PAUSE_AFTER_SERVICE_SNAPSHOT=1

  invoke_herdr_script >"${TEST_TMP}/first.out" 2>&1 &
  first_pid=$!
  if wait_for_file "${SERVICE_SNAPSHOT_FILE}"; then
    snapshot_seen=1
  fi

  invoke_herdr_script >"${TEST_TMP}/second.out" 2>&1 &
  second_pid=$!
  if wait_for_file "${LOCK_WAITING_FILE}"; then
    second_waited=1
  fi

  touch "${RELEASE_SNAPSHOT_FILE}"
  wait "${first_pid}" || first_status=$?
  wait "${second_pid}" || second_status=$?

  [ "${snapshot_seen}" -eq 1 ]
  [ "${second_waited}" -eq 1 ]
  [ "${first_status}" -eq 0 ]
  [ "${second_status}" -eq 0 ]
  [ "$(grep -Fxc 'herdr server stop' "${COMMAND_LOG}")" -eq 1 ]
  [ "$(grep -Fxc 'brew services start herdr' "${COMMAND_LOG}")" -eq 1 ]
  [[ "$(<"${TEST_TMP}/second.out")" == *"already healthy"* ]]
}

@test "restores the Homebrew job when a post-stop status query fails" {
  write_service_list "${error_service}"
  write_herdr_status "${old_herdr_status}"
  printf '%s\n' "${healthy_herdr_status}" >"${HERDR_AFTER_START_FILE}"
  BREW_LIST_FAIL_AT=2

  run_herdr_script

  [ "$status" -eq 1 ]
  grep -Fxq 'brew services stop herdr' "${COMMAND_LOG}"
  grep -Fxq 'brew services start herdr' "${COMMAND_LOG}"
  [[ "$output" == *"Restoring the Herdr Homebrew service after a status query failure"* ]]
}

@test "hands off an incompatible server even when its service reports started" {
  write_service_list "${started_service}"
  write_herdr_status "${old_herdr_status}"
  printf '%s\n' "${healthy_herdr_status}" >"${HERDR_AFTER_START_FILE}"

  run_herdr_script

  [ "$status" -eq 0 ]
  grep -Fxq 'brew services stop herdr' "${COMMAND_LOG}"
  grep -Fxq 'herdr server stop' "${COMMAND_LOG}"
  grep -Fxq 'brew services start herdr' "${COMMAND_LOG}"
}

@test "restarts a started service whose server is not running" {
  write_service_list "${started_service}"
  write_herdr_status "${not_running_herdr_status}"
  printf '%s\n' "${healthy_herdr_status}" >"${HERDR_AFTER_START_FILE}"

  run_herdr_script

  [ "$status" -eq 0 ]
  grep -Fxq 'brew services stop herdr' "${COMMAND_LOG}"
  assert_command_not_logged 'herdr server stop'
  grep -Fxq 'brew services start herdr' "${COMMAND_LOG}"
}

@test "reports a Homebrew service start failure" {
  write_service_list "${missing_service}"
  write_herdr_status "${not_running_herdr_status}"
  BREW_START_FAIL=1

  run_herdr_script

  [ "$status" -eq 1 ]
  [[ "$output" == *"Failed to start the Herdr Homebrew service"* ]]
}
