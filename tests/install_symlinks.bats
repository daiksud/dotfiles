#!/usr/bin/env bats

INSTALL_SH="${BATS_TEST_DIRNAME}/../install.sh"

setup() {
  SANDBOX="$(cd "$(mktemp -d)" && pwd -P)"
  FAKE_HOME="$(cd "$(mktemp -d)" && pwd -P)"
  mkdir -p "${SANDBOX}/scripts" "${SANDBOX}/dotfiles"
  cp "${INSTALL_SH}" "${SANDBOX}/install.sh"
}

teardown() {
  rm -rf "$SANDBOX" "$FAKE_HOME"
}

write_install_map() {
  printf '{"links": %s}\n' "$1" >"${SANDBOX}/install_map.json"
}

run_install() {
  HOME="$FAKE_HOME" /bin/bash "${SANDBOX}/install.sh"
}

@test "creates a symlink for each mapping" {
  printf 'hello-a\n' >"${SANDBOX}/dotfiles/a.txt"
  printf 'hello-b\n' >"${SANDBOX}/dotfiles/b.txt"
  write_install_map '{"a.txt": "~/dst-a.txt", "b.txt": ["~/nested/dst-b.txt"]}'

  run run_install

  [ "$status" -eq 0 ]
  [ -L "${FAKE_HOME}/dst-a.txt" ]
  [ "$(cat "${FAKE_HOME}/dst-a.txt")" = "hello-a" ]
  [ -L "${FAKE_HOME}/nested/dst-b.txt" ]
  [ "$(cat "${FAKE_HOME}/nested/dst-b.txt")" = "hello-b" ]
}

@test "re-running install.sh is idempotent" {
  printf 'hello\n' >"${SANDBOX}/dotfiles/a.txt"
  write_install_map '{"a.txt": "~/dst-a.txt"}'

  run run_install
  [ "$status" -eq 0 ]
  run run_install
  [ "$status" -eq 0 ]
  [ -L "${FAKE_HOME}/dst-a.txt" ]
}
