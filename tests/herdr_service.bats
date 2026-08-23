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
  PYTHON_BIN="$(command -v python3)"

  mkdir -p "${FAKE_BIN}"

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
  cat "${BREW_SERVICE_FILE}"
  ;;
"services stop herdr")
  if [[ "${BREW_STOP_FAIL:-0}" == "1" ]]; then
    echo "fake brew stop failure" >&2
    exit 1
  fi
  set_service_status stopped
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

  chmod +x "${FAKE_BIN}/uname" "${FAKE_BIN}/brew" "${FAKE_BIN}/herdr"
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

run_herdr_script() {
  run env \
    PATH="${FAKE_BIN}:/usr/bin:/bin" \
    FAKE_UNAME="${FAKE_UNAME:-Darwin}" \
    COMMAND_LOG="${COMMAND_LOG}" \
    BREW_SERVICE_FILE="${BREW_SERVICE_FILE}" \
    HERDR_STATUS_FILE="${HERDR_STATUS_FILE}" \
    HERDR_AFTER_START_FILE="${HERDR_AFTER_START_FILE}" \
    SERVICE_STARTED_FILE="${SERVICE_STARTED_FILE}" \
    DOTFILES_BREW_BIN="${FAKE_BIN}/brew" \
    DOTFILES_HERDR_BIN="${FAKE_BIN}/herdr" \
    DOTFILES_PYTHON_BIN="${PYTHON_BIN}" \
    DOTFILES_HERDR_WAIT_ATTEMPTS=1 \
    DOTFILES_HERDR_WAIT_SECONDS=0 \
    BREW_STOP_FAIL="${BREW_STOP_FAIL:-0}" \
    BREW_START_FAIL="${BREW_START_FAIL:-0}" \
    HERDR_STOP_FAIL="${HERDR_STOP_FAIL:-0}" \
    "${SCRIPT}"
}

healthy_herdr_status='{"status":"running","running":true,"version":"0.8.2","protocol":20,"capabilities":{"live_handoff":true},"compatible":true,"socket":"/tmp/herdr.sock","session":null,"restart_needed":false}'
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
  ! grep -Fxq 'brew services stop herdr' "${COMMAND_LOG}"
  [[ "$output" == *"Herdr service is running"* ]]
}

@test "preserves a healthy managed service" {
  write_service_list "${started_service}"
  write_herdr_status "${healthy_herdr_status}"

  run_herdr_script

  [ "$status" -eq 0 ]
  ! grep -Fxq 'brew services start herdr' "${COMMAND_LOG}"
  ! grep -Fxq 'brew services stop herdr' "${COMMAND_LOG}"
  [[ "$output" == *"already healthy"* ]]
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

@test "reports a Homebrew service start failure" {
  write_service_list "${missing_service}"
  write_herdr_status "${not_running_herdr_status}"
  BREW_START_FAIL=1

  run_herdr_script

  [ "$status" -eq 1 ]
  [[ "$output" == *"Failed to start the Herdr Homebrew service"* ]]
}
