#!/usr/bin/env bats
# Behavior tests for dotfiles/ghostty/herdr-launch.sh.
#
# Ghostty's GUI process starts with a minimal PATH (no Homebrew), so the
# wrapper must resolve herdr from known Homebrew bin directories, fall back
# to a login shell when herdr is unavailable, and avoid a nested launch when
# already running inside a herdr pane. Each test stubs `herdr` and the login
# shell under a temp directory (via HERDR_LAUNCH_BREW_BINS and SHELL) so no
# real Homebrew installation or herdr binary is required.

SCRIPT="${BATS_TEST_DIRNAME}/../dotfiles/ghostty/herdr-launch.sh"

setup() {
  TEST_TMP="$(mktemp -d)"
  BREW_BIN="$TEST_TMP/brewbin"
  EMPTY_BIN="$TEST_TMP/empty-bin"
  mkdir -p "$BREW_BIN" "$EMPTY_BIN"

  cat >"$BREW_BIN/herdr" <<'EOF'
#!/bin/sh
echo "herdr-launched"
EOF
  chmod +x "$BREW_BIN/herdr"

  FAKE_SHELL="$TEST_TMP/fake-login-shell"
  cat >"$FAKE_SHELL" <<'EOF'
#!/bin/sh
echo "login-shell-launched args=$*"
EOF
  chmod +x "$FAKE_SHELL"
}

teardown() {
  rm -rf "$TEST_TMP"
}

@test "resolves and launches herdr from a Homebrew-style bin directory" {
  run env -i HOME="$HOME" PATH=/usr/bin:/bin SHELL="$FAKE_SHELL" \
    HERDR_LAUNCH_BREW_BINS="$BREW_BIN" "$SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "herdr-launched" ]
}

@test "falls back to the login shell when herdr is not found" {
  run env -i HOME="$HOME" PATH=/usr/bin:/bin SHELL="$FAKE_SHELL" \
    HERDR_LAUNCH_BREW_BINS="$EMPTY_BIN" "$SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "login-shell-launched args=-l" ]
}

@test "falls back to the login shell instead of nesting inside a herdr pane" {
  run env -i HOME="$HOME" PATH=/usr/bin:/bin SHELL="$FAKE_SHELL" \
    HERDR_LAUNCH_BREW_BINS="$BREW_BIN" HERDR_ENV=1 "$SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "login-shell-launched args=-l" ]
}
