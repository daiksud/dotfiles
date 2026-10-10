#!/usr/bin/env bats

setup() {
  TEST_TMP="$(mktemp -d)"
  mkdir -p "$TEST_TMP/bin" "$TEST_TMP/home" "$TEST_TMP/repo/scripts" "$TEST_TMP/elsewhere"
  export SETUP_LOG="$TEST_TMP/setup.log"
  : > "$SETUP_LOG"

  cat > "$TEST_TMP/bin/uname" <<'STUB'
#!/bin/bash
echo Darwin
STUB
  cat > "$TEST_TMP/bin/brew" <<'STUB'
#!/bin/bash
exit 0
STUB
  cat > "$TEST_TMP/bin/mise" <<'STUB'
#!/bin/bash
printf '%s|%s\n' "$PWD" "$*" >> "$SETUP_LOG"
exit "${INSTALL_STATUS:-0}"
STUB

  chmod +x "$TEST_TMP/bin/"*
  sed "s|/opt/homebrew/bin/brew|$TEST_TMP/bin/brew|g" \
    "$BATS_TEST_DIRNAME/../scripts/100-mise.sh" > "$TEST_TMP/repo/scripts/100-mise.sh"
}

teardown() {
  rm -rf "$TEST_TMP"
}

execute_setup() {
  cd "$TEST_TMP/elsewhere" || return 1
  env -i HOME="$TEST_TMP/home" PATH="$TEST_TMP/bin:/usr/bin:/bin" \
    SETUP_LOG="$SETUP_LOG" INSTALL_STATUS="${1:-0}" \
    bash "$TEST_TMP/repo/scripts/100-mise.sh"
}

@test "mise setup installs repository tooling from any caller directory" {
  run execute_setup
  [ "$status" -eq 0 ] || return 1
  [ "$(cat "$SETUP_LOG")" = "$TEST_TMP/repo|install" ]
}

@test "mise setup propagates provisioning errors" {
  run execute_setup 17
  [ "$status" -eq 17 ] || return 1
  [ "$(cat "$SETUP_LOG")" = "$TEST_TMP/repo|install" ]
}
