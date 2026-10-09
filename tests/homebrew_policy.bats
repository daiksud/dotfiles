#!/usr/bin/env bats

setup() {
  TEST_TMP="$(mktemp -d)"
  mkdir -p "$TEST_TMP/bin" "$TEST_TMP/home"
  export BREW_LOG="$TEST_TMP/brew.log"
  : > "$BREW_LOG"
  cat > "$TEST_TMP/bin/brew" <<'STUB'
#!/bin/bash
if [ "$1" != shellenv ]; then
  echo "$*" >> "$BREW_LOG"
fi
STUB
  cat > "$TEST_TMP/bin/uname" <<'STUB'
#!/bin/bash
echo "$TEST_OS"
STUB
  chmod +x "$TEST_TMP/bin/"*
  # Replace only host shellenv paths; preserve the setup commands under test.
  sed -e "s|/opt/homebrew/bin/brew|$TEST_TMP/bin/brew|g" \
      -e "s|/home/linuxbrew/.linuxbrew/bin/brew|$TEST_TMP/bin/brew|g" \
      "$BATS_TEST_DIRNAME/../scripts/001-homebrew.sh" > "$TEST_TMP/homebrew.sh"
}

teardown() {
  rm -rf "$TEST_TMP"
}

check_formula_upgrade() {
  run env -i HOME="$TEST_TMP/home" PATH="$TEST_TMP/bin:/usr/bin:/bin" \
    BREW_LOG="$BREW_LOG" TEST_OS="$1" bash "$TEST_TMP/homebrew.sh"
  [ "$status" -eq 0 ]
  [ "$(cat "$BREW_LOG")" = $'install --quiet gcc\nupgrade --quiet --formula' ]
}

@test "macOS setup upgrades formulas without managing installed Casks" {
  check_formula_upgrade Darwin
}

@test "Linux setup retains formula installation and upgrades" {
  check_formula_upgrade Linux
}
