#!/usr/bin/env bats
# Behavior tests for the symlink-creation logic in install.sh.
#
# Each test copies the real, current install.sh into an isolated sandbox
# alongside a minimal fixture install_map.json + fixture dotfiles/ + an EMPTY
# scripts/ directory (so the scripts-running part of install.sh is a no-op —
# no real installs happen), then runs it with HOME pointed at a temp fake
# home. This exercises the actual symlink/migration logic without touching
# the real machine or invoking Homebrew/apt/network.

INSTALL_SH="${BATS_TEST_DIRNAME}/../install.sh"

setup() {
  ORIGINAL_DIR="$(pwd)"
  # install.sh resolves its own location with `readlink -f`, so canonicalize
  # these sandbox paths the same way (e.g. macOS resolves /tmp -> /private/tmp)
  # to keep path comparisons below consistent with what install.sh sees.
  SANDBOX="$(cd "$(mktemp -d)" && pwd -P)"
  FAKE_HOME="$(cd "$(mktemp -d)" && pwd -P)"

  mkdir -p "${SANDBOX}/scripts" "${SANDBOX}/dotfiles"
  cp "${INSTALL_SH}" "${SANDBOX}/install.sh"
}

teardown() {
  cd "$ORIGINAL_DIR"
  rm -rf "$SANDBOX" "$FAKE_HOME"
}

write_install_map() {
  # write_install_map '{"a.txt": "~/dst-a.txt", ...}'
  printf '{"links": %s}\n' "$1" >"${SANDBOX}/install_map.json"
}

run_install() {
  HOME="$FAKE_HOME" bash "${SANDBOX}/install.sh"
}

@test "creates a symlink for each mapping in install_map.json" {
  mkdir -p "${SANDBOX}/dotfiles/sub"
  printf 'hello-a\n' >"${SANDBOX}/dotfiles/a.txt"
  printf 'hello-b\n' >"${SANDBOX}/dotfiles/sub/b.txt"
  write_install_map '{"a.txt": "~/dst-a.txt", "sub/b.txt": "~/nested/dst-b.txt"}'

  run run_install

  [ "$status" -eq 0 ]

  [ -L "${FAKE_HOME}/dst-a.txt" ]
  [ "$(readlink "${FAKE_HOME}/dst-a.txt")" = "${SANDBOX}/dotfiles/a.txt" ]
  [ "$(cat "${FAKE_HOME}/dst-a.txt")" = "hello-a" ]

  # ~/nested did not exist beforehand: mkdir -p must have created it.
  [ -L "${FAKE_HOME}/nested/dst-b.txt" ]
  [ "$(cat "${FAKE_HOME}/nested/dst-b.txt")" = "hello-b" ]
}

@test "re-running install.sh is idempotent" {
  printf 'hello-a\n' >"${SANDBOX}/dotfiles/a.txt"
  write_install_map '{"a.txt": "~/dst-a.txt"}'

  run run_install
  [ "$status" -eq 0 ]

  run run_install
  [ "$status" -eq 0 ]

  [ -L "${FAKE_HOME}/dst-a.txt" ]
  [ "$(readlink "${FAKE_HOME}/dst-a.txt")" = "${SANDBOX}/dotfiles/a.txt" ]
}

@test "converts a symlinked parent directory into a real directory and migrates its existing contents" {
  printf 'fixture-c\n' >"${SANDBOX}/dotfiles/c.txt"
  write_install_map '{"c.txt": "~/.config/tool/c.txt"}'

  # Pre-existing setup: ~/.config/tool is a symlink to another directory that
  # already has unrelated content in it.
  mkdir -p "${FAKE_HOME}/.config" "${FAKE_HOME}/tool-target"
  printf 'keep-me\n' >"${FAKE_HOME}/tool-target/existing.txt"
  ln -s "${FAKE_HOME}/tool-target" "${FAKE_HOME}/.config/tool"

  run run_install

  [ "$status" -eq 0 ]

  # The former symlink is now a real directory.
  [ ! -L "${FAKE_HOME}/.config/tool" ]
  [ -d "${FAKE_HOME}/.config/tool" ]

  # Pre-existing content was migrated in, not lost.
  [ -f "${FAKE_HOME}/.config/tool/existing.txt" ]
  [ "$(cat "${FAKE_HOME}/.config/tool/existing.txt")" = "keep-me" ]
  [ ! -e "${FAKE_HOME}/tool-target/existing.txt" ]

  # The new mapping was linked inside the now-real directory.
  [ -L "${FAKE_HOME}/.config/tool/c.txt" ]
  [ "$(cat "${FAKE_HOME}/.config/tool/c.txt")" = "fixture-c" ]
}
