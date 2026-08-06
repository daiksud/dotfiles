#!/usr/bin/env bats

# Behavior coverage for dotfiles/zsh/repository-select.zsh.

PLUGIN="${BATS_TEST_DIRNAME}/../dotfiles/zsh/repository-select.zsh"

setup() {
  TEST_TMP="$(mktemp -d)"
  export TEST_TMP
}

teardown() {
  [ -n "${TEST_TMP:-}" ] && rm -rf "$TEST_TMP"
}

@test "the plugin parses as valid Zsh" {
  run zsh -n "$PLUGIN"
  [ "$status" -eq 0 ]
}

@test "a missing fzf produces a clear, immediate error" {
  # Regression test: repository-select-path used to fall straight through to
  # `| fzf` without checking for it first, surfacing only a generic
  # "command not found: fzf" instead of a message consistent with the
  # existing "gh is not installed" check.
  local real_gh real_zsh
  real_gh="$(command -v gh)"
  real_zsh="$(command -v zsh)"
  mkdir -p "${TEST_TMP}/bin"
  ln -s "$real_gh" "${TEST_TMP}/bin/gh"

  run env PATH="${TEST_TMP}/bin" "$real_zsh" -c '
    source '"$PLUGIN"'
    repository-select-path
  '
  [ "$status" -eq 1 ]
  [[ "$output" == *"repository-select-path: fzf is not installed"* ]]
}
