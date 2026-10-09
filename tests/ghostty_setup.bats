#!/usr/bin/env bats

setup() {
  TEST_TMP="$(mktemp -d)"
  mkdir -p "$TEST_TMP/bin" "$TEST_TMP/home"
  export SETUP_LOG="$TEST_TMP/setup.log"
  : > "$SETUP_LOG"
  cat > "$TEST_TMP/bin/uname" <<'STUB'
#!/bin/bash
echo "$TEST_OS"
STUB
  cat > "$TEST_TMP/bin/brew" <<'STUB'
#!/bin/bash
echo "brew $*" >> "$SETUP_LOG"
exit 1
STUB
  cat > "$TEST_TMP/bin/curl" <<'STUB'
#!/bin/bash
echo "curl $*" >> "$SETUP_LOG"
echo 'echo linux-installer-stub'
STUB
  chmod +x "$TEST_TMP/bin/"*
  # Isolate the app and brew paths without changing platform decisions.
  sed -e "s|/Applications/Ghostty.app|$TEST_TMP/Ghostty.app|g" \
      -e "s|/opt/homebrew/bin/brew|$TEST_TMP/bin/brew|g" \
      "$BATS_TEST_DIRNAME/../scripts/100-ghostty.sh" > "$TEST_TMP/ghostty.sh"
}

teardown() {
  rm -rf "$TEST_TMP"
}

execute_setup() {
  env -i HOME="$TEST_TMP/home" PATH="$TEST_TMP/bin:/usr/bin:/bin" \
    SETUP_LOG="$SETUP_LOG" TEST_OS="$1" bash "$TEST_TMP/ghostty.sh"
}

@test "macOS missing Ghostty gives manual installation instructions without package operations" {
  run execute_setup Darwin
  [ "$status" -eq 0 ] || return 1
  [[ "$output" == *"https://ghostty.org/download"* ]] || return 1
  [ ! -s "$SETUP_LOG" ] || return 1
}

@test "macOS direct-download app provides terminfo without Homebrew" {
  mkdir -p "$TEST_TMP/Ghostty.app/Contents/Resources/terminfo/g"
  echo terminfo-fixture > "$TEST_TMP/Ghostty.app/Contents/Resources/terminfo/g/ghostty"
  run execute_setup Darwin
  [ "$status" -eq 0 ] || return 1
  [ "$(cat "$TEST_TMP/home/.terminfo/g/ghostty")" = terminfo-fixture ] || return 1
  [ ! -s "$SETUP_LOG" ] || return 1
}

@test "Linux retains the existing Ghostty installer" {
  run execute_setup Linux
  [ "$status" -eq 0 ] || return 1
  [ "$output" = linux-installer-stub ] || return 1
  [ "$(cat "$SETUP_LOG")" = 'curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh' ] || return 1
}

@test "existing Ghostty command skips installation" {
  printf '#!/bin/bash\nexit 0\n' > "$TEST_TMP/bin/ghostty"
  chmod +x "$TEST_TMP/bin/ghostty"
  run execute_setup Darwin
  [ "$status" -eq 0 ] || return 1
  [ "$output" = '' ] || return 1
  [ ! -s "$SETUP_LOG" ] || return 1
}
