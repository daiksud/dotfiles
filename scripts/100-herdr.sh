#!/bin/bash

# Keep the herdr server resident across reboots so panes and agents survive
# terminal restarts. `brew services` manages this via launchd, which is
# macOS-only; on Linux (e.g. Codespaces) herdr is simply run on demand.
if [[ "$(uname)" != "Darwin" ]]; then
  exit 0
fi

LOCKF_BIN="${DOTFILES_LOCKF_BIN:-/usr/bin/lockf}"
LOCK_FILE="${DOTFILES_HERDR_LOCK_FILE:-${TMPDIR:-/tmp}/dotfiles-herdr-service-${UID}.lock}"

# Serialize the complete read-decide-write cycle. A status re-check alone
# cannot prevent another installer from replacing the server between that
# check and the destructive stop command.
if [[ "${DOTFILES_HERDR_SERVICE_LOCKED:-0}" != "1" ]]; then
  if [[ ! -x "${LOCKF_BIN}" ]]; then
    echo "Lock utility not found: ${LOCKF_BIN}" >&2
    exit 1
  fi
  export DOTFILES_HERDR_SERVICE_LOCKED=1
  exec "${LOCKF_BIN}" -k "${LOCK_FILE}" /bin/bash "$0" "$@"
fi

BREW_BIN="${DOTFILES_BREW_BIN:-/opt/homebrew/bin/brew}"
HERDR_BIN="${DOTFILES_HERDR_BIN:-herdr}"
PYTHON_BIN="${DOTFILES_PYTHON_BIN:-python3}"
WAIT_ATTEMPTS="${DOTFILES_HERDR_WAIT_ATTEMPTS:-10}"
WAIT_SECONDS="${DOTFILES_HERDR_WAIT_SECONDS:-1}"

if [[ ! -x "${BREW_BIN}" ]]; then
  echo "Homebrew executable not found: ${BREW_BIN}" >&2
  exit 1
fi

if ! brew_shellenv="$("${BREW_BIN}" shellenv 2>&1)"; then
  echo "Cannot initialize the Homebrew environment" >&2
  echo "${brew_shellenv}" >&2
  exit 1
fi
eval "${brew_shellenv}"

if ! [[ "${WAIT_ATTEMPTS}" =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid Herdr service wait attempts: ${WAIT_ATTEMPTS}" >&2
  exit 1
fi
if ! [[ "${WAIT_SECONDS}" =~ ^[0-9]+$ ]]; then
  echo "Invalid Herdr service wait seconds: ${WAIT_SECONDS}" >&2
  exit 1
fi

parse_herdr_status() {
  "${PYTHON_BIN}" -c '
import json
import sys

status = json.load(sys.stdin)
if not isinstance(status, dict):
    raise TypeError("Herdr status must be an object")

required = ("running", "restart_needed", "compatible")
missing = [key for key in required if key not in status]
if missing:
    raise KeyError("Herdr status is missing: " + ", ".join(missing))

def boolean(value):
    if value is True:
        return "1"
    if value is False:
        return "0"
    return "unknown"

version = status.get("version")
protocol = status.get("protocol")
print("\t".join((
    boolean(status["running"]),
    boolean(status["restart_needed"]),
    boolean(status["compatible"]),
    str(version) if version is not None else "-",
    str(protocol) if protocol is not None else "-",
)))
'
}

parse_service_status() {
  "${PYTHON_BIN}" -c '
import json
import sys

services = json.load(sys.stdin)
if not isinstance(services, list):
    raise TypeError("Homebrew service status must be an array")

for service in services:
    if not isinstance(service, dict):
        raise TypeError("Homebrew service entry must be an object")
    if service.get("name") == "herdr":
        status = service.get("status")
        if not isinstance(status, str) or not status:
            raise ValueError("Homebrew service status is missing")
        print(status)
        break
else:
    print("missing")
'
}

run_default_herdr() {
  (
    unset HERDR_SOCKET_PATH HERDR_SESSION
    "${HERDR_BIN}" "$@"
  )
}

query_herdr_status() {
  local status_json
  local parsed_status

  if ! status_json="$(run_default_herdr status server --json 2>&1)"; then
    echo "Cannot query the Herdr server status" >&2
    echo "${status_json}" >&2
    return 1
  fi
  if ! parsed_status="$(printf '%s' "${status_json}" | parse_herdr_status 2>&1)"; then
    echo "Cannot parse the Herdr server status" >&2
    echo "${parsed_status}" >&2
    return 1
  fi
  printf '%s\n' "${parsed_status}"
}

query_service_status() {
  local services_json
  local service_status

  if ! services_json="$("${BREW_BIN}" services list --json 2>&1)"; then
    echo "Cannot query the Homebrew service status" >&2
    echo "${services_json}" >&2
    return 1
  fi
  if ! service_status="$(printf '%s' "${services_json}" | parse_service_status 2>&1)"; then
    echo "Cannot parse the Homebrew service status" >&2
    echo "${service_status}" >&2
    return 1
  fi
  printf '%s\n' "${service_status}"
}

stop_homebrew_service() {
  echo "Stopping the existing Herdr Homebrew service"
  if ! "${BREW_BIN}" services stop herdr; then
    echo "Failed to stop the existing Herdr Homebrew service" >&2
    return 1
  fi
}

stop_herdr_server() {
  echo "Stopping the existing Herdr server; its panes will exit"
  if ! run_default_herdr server stop; then
    echo "Failed to stop the existing Herdr server" >&2
    return 1
  fi
}

start_homebrew_service() {
  echo "Starting the Herdr Homebrew service"
  if ! "${BREW_BIN}" services start herdr; then
    echo "Failed to start the Herdr Homebrew service" >&2
    return 1
  fi
}

restore_homebrew_service_after_query_failure() {
  echo "Restoring the Herdr Homebrew service after a status query failure" >&2
  if ! start_homebrew_service; then
    echo "The Herdr Homebrew service could not be restored automatically" >&2
  fi
}

service_is_healthy() {
  local service_status="$1"
  local server_running="$2"
  local compatible="$3"

  [[ "${service_status}" == "started" &&
    "${server_running}" == "1" &&
    "${compatible}" == "1" ]]
}

verify_service() {
  local attempt
  local service_status
  local herdr_status
  local server_running
  local restart_needed
  local compatible
  local server_version
  local server_protocol

  for ((attempt = 1; attempt <= WAIT_ATTEMPTS; attempt++)); do
    service_status="$(query_service_status)" || return 1
    herdr_status="$(query_herdr_status)" || return 1
    IFS=$'\t' read -r server_running restart_needed compatible server_version server_protocol <<<"${herdr_status}"

    if service_is_healthy "${service_status}" "${server_running}" "${compatible}"; then
      echo "Herdr service is running (${server_version}, protocol ${server_protocol})"
      return 0
    fi

    if ((attempt < WAIT_ATTEMPTS && WAIT_SECONDS > 0)); then
      sleep "${WAIT_SECONDS}"
    fi
  done

  echo "Herdr service did not become healthy" >&2
  echo "  Homebrew service status: ${service_status}" >&2
  echo "  Herdr server: running=${server_running}, compatible=${compatible}, restart_needed=${restart_needed}, version=${server_version}, protocol=${server_protocol}" >&2
  return 1
}

herdr_status="$(query_herdr_status)" || exit 1
service_status="$(query_service_status)" || exit 1
IFS=$'\t' read -r server_running restart_needed compatible server_version server_protocol <<<"${herdr_status}"

if service_is_healthy "${service_status}" "${server_running}" "${compatible}"; then
  echo "Herdr service is already healthy (${server_version}, protocol ${server_protocol})"
  exit 0
fi

if [[ "${server_running}" == "1" ]]; then
  echo "Herdr server requires a Homebrew service handoff (${server_version}, protocol ${server_protocol})"
elif [[ "${service_status}" != "missing" && "${service_status}" != "stopped" ]]; then
  echo "Herdr Homebrew service is ${service_status} but its server is not running"
fi

case "${service_status}" in
started | error | missing | none | stopped)
  ;;
*)
  echo "Unsupported Herdr Homebrew service status: ${service_status}" >&2
  exit 1
  ;;
esac

if [[ "${server_running}" == "1" && "${HERDR_ENV:-}" == "1" ]]; then
  echo "Cannot hand off the default Herdr server from a Herdr-managed pane" >&2
  echo "Re-run install.sh from a plain shell after saving work in the default session" >&2
  exit 1
fi

case "${service_status}" in
started | error)
  stop_homebrew_service || exit 1
  service_stop_completed=1
  ;;
*) service_stop_completed=0 ;;
esac

# Stopping a loaded service may already terminate the process it manages, and
# launchd may change state independently. Re-read both authoritative states
# before issuing either remaining lifecycle command.
if ! herdr_status="$(query_herdr_status)"; then
  if [[ "${service_stop_completed}" == "1" ]]; then
    restore_homebrew_service_after_query_failure
  fi
  exit 1
fi
if ! service_status="$(query_service_status)"; then
  if [[ "${service_stop_completed}" == "1" ]]; then
    restore_homebrew_service_after_query_failure
  fi
  exit 1
fi
IFS=$'\t' read -r server_running restart_needed compatible server_version server_protocol <<<"${herdr_status}"

if service_is_healthy "${service_status}" "${server_running}" "${compatible}"; then
  echo "Herdr service became healthy during handoff (${server_version}, protocol ${server_protocol})"
  exit 0
fi

if [[ "${server_running}" == "1" ]]; then
  stop_herdr_server || exit 1
fi

start_homebrew_service || exit 1
verify_service
