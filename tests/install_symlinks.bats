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
  cd "$ORIGINAL_DIR" || return
  rm -rf "$SANDBOX" "$FAKE_HOME"
}

write_install_map() {
  # write_install_map '{"a.txt": "~/dst-a.txt", ...}' '["~/.agents/skills"]'
  local skill_targets="${2:-[]}"
  printf '{"links": %s, "skill_targets": %s}\n' "$1" "$skill_targets" >"${SANDBOX}/install_map.json"
}

run_install() {
  HOME="$FAKE_HOME" /bin/bash "${SANDBOX}/install.sh"
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

@test "creates every destination when a mapping contains an array" {
  printf 'shared\n' >"${SANDBOX}/dotfiles/shared.txt"
  write_install_map '{"shared.txt": ["~/.copilot/instructions.md", "~/.codex/AGENTS.md", "~/.claude/CLAUDE.md"]}'

  run run_install

  [ "$status" -eq 0 ]
  for dst in \
    "${FAKE_HOME}/.copilot/instructions.md" \
    "${FAKE_HOME}/.codex/AGENTS.md" \
    "${FAKE_HOME}/.claude/CLAUDE.md"; do
    [ -L "$dst" ]
    [ "$(readlink "$dst")" = "${SANDBOX}/dotfiles/shared.txt" ]
  done
}

@test "preserves symlinked agent config roots when linking shared instructions" {
  printf 'shared\n' >"${SANDBOX}/dotfiles/shared.txt"
  mkdir -p "${SANDBOX}/dotfiles/skills/managed"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  write_install_map \
    '{"shared.txt": ["~/.copilot/instructions.md", "~/.codex/AGENTS.md", "~/.claude/CLAUDE.md"]}' \
    '["~/.agents/skills", "~/.claude/skills"]'

  for agent in copilot codex claude; do
    mkdir -p "${FAKE_HOME}/relocated/${agent}"
    printf 'keep-%s\n' "${agent}" >"${FAKE_HOME}/relocated/${agent}/existing.txt"
    ln -s "relocated/${agent}" "${FAKE_HOME}/.${agent}"
  done

  run env HOME="${FAKE_HOME}/" /bin/bash "${SANDBOX}/install.sh"

  [ "$status" -eq 0 ]
  for agent in copilot codex claude; do
    [ -L "${FAKE_HOME}/.${agent}" ]
    [ "$(readlink "${FAKE_HOME}/.${agent}")" = "relocated/${agent}" ]
    [ "$(cat "${FAKE_HOME}/.${agent}/existing.txt")" = "keep-${agent}" ]
  done
  [ -L "${FAKE_HOME}/.copilot/instructions.md" ]
  [ -L "${FAKE_HOME}/.codex/AGENTS.md" ]
  [ -L "${FAKE_HOME}/.claude/CLAUDE.md" ]
  [ -L "${FAKE_HOME}/.claude/skills/managed" ]
  [ "$(readlink "${FAKE_HOME}/.claude/skills/managed")" = "${SANDBOX}/dotfiles/skills/managed" ]
}

@test "leaves a dangling agent config root intact and fails installation" {
  printf 'shared\n' >"${SANDBOX}/dotfiles/shared.txt"
  write_install_map '{"shared.txt": "~/.codex/AGENTS.md"}'

  ln -s "missing-codex-config" "${FAKE_HOME}/.codex"

  run run_install

  [ "$status" -ne 0 ]
  [[ "$output" == *"symlinked agent config directory"* ]]
  [[ "$output" == *"target is not an existing directory"* ]]
  [ -L "${FAKE_HOME}/.codex" ]
  [ "$(readlink "${FAKE_HOME}/.codex")" = "missing-codex-config" ]
}

@test "leaves an agent config root linked to a file intact and fails installation" {
  printf 'shared\n' >"${SANDBOX}/dotfiles/shared.txt"
  write_install_map '{"shared.txt": "~/.claude/CLAUDE.md"}'

  printf 'not a directory\n' >"${FAKE_HOME}/claude-config-file"
  ln -s "claude-config-file" "${FAKE_HOME}/.claude"

  run run_install

  [ "$status" -ne 0 ]
  [[ "$output" == *"symlinked agent config directory"* ]]
  [[ "$output" == *"target is not an existing directory"* ]]
  [ -L "${FAKE_HOME}/.claude" ]
  [ "$(readlink "${FAKE_HOME}/.claude")" = "claude-config-file" ]
  [ "$(cat "${FAKE_HOME}/claude-config-file")" = "not a directory" ]
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
  printf 'keep-hidden\n' >"${FAKE_HOME}/tool-target/..existing"
  ln -s "${FAKE_HOME}/tool-target" "${FAKE_HOME}/.config/tool"

  run run_install

  [ "$status" -eq 0 ]

  # The former symlink is now a real directory.
  [ ! -L "${FAKE_HOME}/.config/tool" ]
  [ -d "${FAKE_HOME}/.config/tool" ]

  # Pre-existing content was migrated in, not lost.
  [ -f "${FAKE_HOME}/.config/tool/existing.txt" ]
  [ "$(cat "${FAKE_HOME}/.config/tool/existing.txt")" = "keep-me" ]
  [ "$(cat "${FAKE_HOME}/.config/tool/..existing")" = "keep-hidden" ]
  [ ! -e "${FAKE_HOME}/tool-target/existing.txt" ]
  [ ! -e "${FAKE_HOME}/tool-target/..existing" ]

  # The new mapping was linked inside the now-real directory.
  [ -L "${FAKE_HOME}/.config/tool/c.txt" ]
  [ "$(cat "${FAKE_HOME}/.config/tool/c.txt")" = "fixture-c" ]
}

@test "resolves a relative parent symlink target from the symlink directory" {
  printf 'fixture-relative\n' >"${SANDBOX}/dotfiles/relative.txt"
  write_install_map '{"relative.txt": "~/.config/tool/relative.txt"}'

  mkdir -p "${FAKE_HOME}/.config" "${FAKE_HOME}/tool-target"
  printf 'keep-relative\n' >"${FAKE_HOME}/tool-target/existing.txt"
  ln -s "../tool-target" "${FAKE_HOME}/.config/tool"

  run run_install

  [ "$status" -eq 0 ]
  [ ! -L "${FAKE_HOME}/.config/tool" ]
  [ -d "${FAKE_HOME}/.config/tool" ]
  [ "$(cat "${FAKE_HOME}/.config/tool/existing.txt")" = "keep-relative" ]
  [ ! -e "${FAKE_HOME}/tool-target/existing.txt" ]
  [ -L "${FAKE_HOME}/.config/tool/relative.txt" ]
  [ "$(cat "${FAKE_HOME}/.config/tool/relative.txt")" = "fixture-relative" ]
}

@test "leaves a dangling parent symlink intact and fails installation" {
  printf 'fixture-dangling\n' >"${SANDBOX}/dotfiles/dangling.txt"
  write_install_map '{"dangling.txt": "~/.config/tool/dangling.txt"}'

  mkdir -p "${FAKE_HOME}/.config"
  ln -s "../missing-target" "${FAKE_HOME}/.config/tool"

  run run_install

  [ "$status" -ne 0 ]
  [[ "$output" == *"is not an existing directory"* ]]
  [ -L "${FAKE_HOME}/.config/tool" ]
  [ "$(readlink "${FAKE_HOME}/.config/tool")" = "../missing-target" ]
  [ ! -e "${FAKE_HOME}/.config/tool/dangling.txt" ]
}

@test "leaves a parent symlink to a non-directory intact and fails installation" {
  printf 'fixture-invalid\n' >"${SANDBOX}/dotfiles/invalid.txt"
  write_install_map '{"invalid.txt": "~/.config/tool/invalid.txt"}'

  mkdir -p "${FAKE_HOME}/.config"
  printf 'not a directory\n' >"${FAKE_HOME}/not-a-directory"
  ln -s "../not-a-directory" "${FAKE_HOME}/.config/tool"

  run run_install

  [ "$status" -ne 0 ]
  [[ "$output" == *"is not an existing directory"* ]]
  [ -L "${FAKE_HOME}/.config/tool" ]
  [ "$(readlink "${FAKE_HOME}/.config/tool")" = "../not-a-directory" ]
  [ "$(cat "${FAKE_HOME}/not-a-directory")" = "not a directory" ]
}

@test "keeps the canonical legacy skills link when a later mapping fails" {
  mkdir -p \
    "${SANDBOX}/dotfiles/skills/managed" \
    "${FAKE_HOME}/.copilot" \
    "${FAKE_HOME}/.config"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  printf 'fixture-failure\n' >"${SANDBOX}/dotfiles/failure.txt"
  ln -s "${SANDBOX}/dotfiles/skills" "${FAKE_HOME}/.copilot/skills"
  ln -s "../missing-target" "${FAKE_HOME}/.config/tool"
  write_install_map '{"failure.txt": "~/.config/tool/failure.txt"}' '["~/.agents/skills"]'

  run run_install

  [ "$status" -ne 0 ]
  [ -L "${FAKE_HOME}/.copilot/skills" ]
  [ "$(readlink "${FAKE_HOME}/.copilot/skills")" = "${SANDBOX}/dotfiles/skills" ]
  [ -f "${FAKE_HOME}/.copilot/skills/managed/SKILL.md" ]
  [ ! -e "${FAKE_HOME}/.agents/skills/managed" ]
}

@test "propagates skill target creation failure and keeps the legacy link" {
  mkdir -p \
    "${SANDBOX}/dotfiles/skills/managed" \
    "${FAKE_HOME}/.copilot"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  printf 'blocks skill root\n' >"${FAKE_HOME}/.agents"
  ln -s "${SANDBOX}/dotfiles/skills" "${FAKE_HOME}/.copilot/skills"
  write_install_map '{}' '["~/.agents/skills"]'

  run run_install

  [ "$status" -ne 0 ]
  [ -L "${FAKE_HOME}/.copilot/skills" ]
  [ "$(readlink "${FAKE_HOME}/.copilot/skills")" = "${SANDBOX}/dotfiles/skills" ]
  [ -f "${FAKE_HOME}/.copilot/skills/managed/SKILL.md" ]
}

@test "invalid JSON performs no mapped mutations and keeps the legacy link" {
  mkdir -p \
    "${SANDBOX}/dotfiles/skills/managed" \
    "${FAKE_HOME}/.copilot"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  printf 'mapped source\n' >"${SANDBOX}/dotfiles/mapped.txt"
  printf 'keep destination\n' >"${FAKE_HOME}/mapped.txt"
  ln -s "${SANDBOX}/dotfiles/skills" "${FAKE_HOME}/.copilot/skills"
  printf '%s\n' '{"links":{"mapped.txt":"~/mapped.txt"},"skill_targets":[' >"${SANDBOX}/install_map.json"

  run run_install

  [ "$status" -ne 0 ]
  [ "$(cat "${FAKE_HOME}/mapped.txt")" = "keep destination" ]
  [ -L "${FAKE_HOME}/.copilot/skills" ]
  [ "$(readlink "${FAKE_HOME}/.copilot/skills")" = "${SANDBOX}/dotfiles/skills" ]
}

@test "skill target parser failure occurs before mapped mutations" {
  mkdir -p \
    "${SANDBOX}/dotfiles/skills/managed" \
    "${FAKE_HOME}/.copilot"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  printf 'mapped source\n' >"${SANDBOX}/dotfiles/mapped.txt"
  printf 'keep destination\n' >"${FAKE_HOME}/mapped.txt"
  ln -s "${SANDBOX}/dotfiles/skills" "${FAKE_HOME}/.copilot/skills"
  write_install_map '{"mapped.txt": "~/mapped.txt"}' '[42]'

  run run_install

  [ "$status" -ne 0 ]
  [ "$(cat "${FAKE_HOME}/mapped.txt")" = "keep destination" ]
  [ -L "${FAKE_HOME}/.copilot/skills" ]
  [ "$(readlink "${FAKE_HOME}/.copilot/skills")" = "${SANDBOX}/dotfiles/skills" ]
}

@test "realpath helper failure keeps the legacy link and fails installation" {
  local real_python3
  real_python3="$(command -v python3)"

  mkdir -p \
    "${SANDBOX}/bin" \
    "${SANDBOX}/dotfiles/skills/managed" \
    "${FAKE_HOME}/.copilot"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  ln -s "${SANDBOX}/dotfiles/skills" "${FAKE_HOME}/.copilot/skills"
  write_install_map '{}' '["~/.agents/skills"]'

  printf '%s\n' \
    '#!/bin/bash' \
    'if [[ "$2" == *"os.path.realpath"* ]]; then' \
    '  exit 42' \
    'fi' \
    'exec "${REAL_PYTHON3}" "$@"' >"${SANDBOX}/bin/python3"
  chmod +x "${SANDBOX}/bin/python3"

  run env \
    HOME="${FAKE_HOME}" \
    PATH="${SANDBOX}/bin:${PATH}" \
    REAL_PYTHON3="${real_python3}" \
    /bin/bash "${SANDBOX}/install.sh"

  [ "$status" -ne 0 ]
  [ -L "${FAKE_HOME}/.copilot/skills" ]
  [ "$(readlink "${FAKE_HOME}/.copilot/skills")" = "${SANDBOX}/dotfiles/skills" ]
  [ -f "${FAKE_HOME}/.copilot/skills/managed/SKILL.md" ]
}

@test "links valid skills individually into every target root" {
  mkdir -p \
    "${SANDBOX}/dotfiles/skills/alpha" \
    "${SANDBOX}/dotfiles/skills/bravo" \
    "${SANDBOX}/dotfiles/skills/not-a-skill"
  printf '%s\n' '---' 'name: alpha' '---' >"${SANDBOX}/dotfiles/skills/alpha/SKILL.md"
  printf '%s\n' '---' 'name: bravo' '---' >"${SANDBOX}/dotfiles/skills/bravo/SKILL.md"
  printf 'ignored\n' >"${SANDBOX}/dotfiles/skills/not-a-skill/README.md"
  write_install_map '{}' '["~/.agents/skills", "~/.claude/skills"]'

  run run_install

  [ "$status" -eq 0 ]
  for root in "${FAKE_HOME}/.agents/skills" "${FAKE_HOME}/.claude/skills"; do
    [ -d "$root" ]
    [ ! -L "$root" ]
    [ -L "${root}/alpha" ]
    [ "$(readlink "${root}/alpha")" = "${SANDBOX}/dotfiles/skills/alpha" ]
    [ -L "${root}/bravo" ]
    [ "$(readlink "${root}/bravo")" = "${SANDBOX}/dotfiles/skills/bravo" ]
    [ ! -e "${root}/not-a-skill" ]
  done
}

@test "skill installation preserves unrelated and reserved entries" {
  mkdir -p \
    "${SANDBOX}/dotfiles/skills/managed" \
    "${FAKE_HOME}/.agents/skills/.system" \
    "${FAKE_HOME}/.agents/skills/unrelated" \
    "${FAKE_HOME}/.agents/skills/managed"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  printf 'reserved\n' >"${FAKE_HOME}/.agents/skills/.system/keep.txt"
  printf 'unrelated\n' >"${FAKE_HOME}/.agents/skills/unrelated/keep.txt"
  printf 'replace me\n' >"${FAKE_HOME}/.agents/skills/managed/stale.txt"
  write_install_map '{}' '["~/.agents/skills"]'

  run run_install

  [ "$status" -eq 0 ]
  [ "$(cat "${FAKE_HOME}/.agents/skills/.system/keep.txt")" = "reserved" ]
  [ "$(cat "${FAKE_HOME}/.agents/skills/unrelated/keep.txt")" = "unrelated" ]
  [ -L "${FAKE_HOME}/.agents/skills/managed" ]
  [ ! -e "${FAKE_HOME}/.agents/skills/managed/stale.txt" ]
}

@test "skill installation is idempotent" {
  mkdir -p "${SANDBOX}/dotfiles/skills/managed"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  write_install_map '{}' '["~/.agents/skills", "~/.claude/skills"]'

  run run_install
  [ "$status" -eq 0 ]
  run run_install
  [ "$status" -eq 0 ]

  [ -L "${FAKE_HOME}/.agents/skills/managed" ]
  [ "$(readlink "${FAKE_HOME}/.agents/skills/managed")" = "${SANDBOX}/dotfiles/skills/managed" ]
  [ -L "${FAKE_HOME}/.claude/skills/managed" ]
  [ "$(readlink "${FAKE_HOME}/.claude/skills/managed")" = "${SANDBOX}/dotfiles/skills/managed" ]
}

@test "does not delete canonical skills through an aliased target root" {
  mkdir -p \
    "${SANDBOX}/dotfiles/skills/managed" \
    "${FAKE_HOME}/.agents"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  ln -s "${SANDBOX}/dotfiles/skills" "${FAKE_HOME}/.agents/skills"
  write_install_map '{}' '["~/.agents/skills"]'

  run run_install

  [ "$status" -eq 0 ]
  [ -L "${FAKE_HOME}/.agents/skills" ]
  [ -f "${SANDBOX}/dotfiles/skills/managed/SKILL.md" ]
}

@test "removes only the legacy Copilot skills link to the canonical source" {
  mkdir -p \
    "${SANDBOX}/dotfiles/skills/managed" \
    "${FAKE_HOME}/.copilot"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  ln -s "${SANDBOX}/dotfiles/skills" "${FAKE_HOME}/.copilot/skills"
  write_install_map '{}' '["~/.agents/skills"]'

  run run_install

  [ "$status" -eq 0 ]
  [ ! -e "${FAKE_HOME}/.copilot/skills" ]
  [ ! -L "${FAKE_HOME}/.copilot/skills" ]
  [ -f "${SANDBOX}/dotfiles/skills/managed/SKILL.md" ]
  [ -L "${FAKE_HOME}/.agents/skills/managed" ]
}

@test "leaves an unrelated legacy Copilot skills path untouched" {
  mkdir -p \
    "${SANDBOX}/dotfiles/skills/managed" \
    "${FAKE_HOME}/.copilot" \
    "${FAKE_HOME}/other-skills/external"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  printf 'keep\n' >"${FAKE_HOME}/other-skills/external/keep.txt"
  ln -s "${FAKE_HOME}/other-skills" "${FAKE_HOME}/.copilot/skills"
  write_install_map '{}' '["~/.agents/skills"]'

  run run_install

  [ "$status" -eq 0 ]
  [ -L "${FAKE_HOME}/.copilot/skills" ]
  [ "$(readlink "${FAKE_HOME}/.copilot/skills")" = "${FAKE_HOME}/other-skills" ]
  [ "$(cat "${FAKE_HOME}/.copilot/skills/external/keep.txt")" = "keep" ]
}

@test "keeps the legacy Copilot skills link without replacement targets" {
  mkdir -p \
    "${SANDBOX}/dotfiles/skills/managed" \
    "${FAKE_HOME}/.copilot"
  printf '%s\n' '---' 'name: managed' '---' >"${SANDBOX}/dotfiles/skills/managed/SKILL.md"
  ln -s "${SANDBOX}/dotfiles/skills" "${FAKE_HOME}/.copilot/skills"
  write_install_map '{}' '[]'

  run run_install

  [ "$status" -eq 0 ]
  [ -L "${FAKE_HOME}/.copilot/skills" ]
  [ "$(readlink "${FAKE_HOME}/.copilot/skills")" = "${SANDBOX}/dotfiles/skills" ]
  [ -f "${FAKE_HOME}/.copilot/skills/managed/SKILL.md" ]
}
