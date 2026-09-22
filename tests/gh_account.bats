#!/usr/bin/env bats

# Regression coverage for dotfiles/zsh/gh-account.zsh. Each test sources the
# plugin outside a Git repository and uses shell functions to avoid real
# credentials and network access.

PLUGIN="${BATS_TEST_DIRNAME}/../dotfiles/zsh/gh-account.zsh"

setup() {
  TEST_TMP="$(mktemp -d)"
  export TEST_TMP
  export MAP_FILE="${TEST_TMP}/repos.json"
}

teardown() {
  [ -n "${TEST_TMP:-}" ] && rm -rf "$TEST_TMP"
}

run_zsh() {
  run zsh -c "
    export GH_ACCOUNT_MAP_FILE='${MAP_FILE}'
    cd '${TEST_TMP}'
    source '${PLUGIN}' >/dev/null 2>&1
    $1
  "
}

@test "identity falls back when the email endpoint writes an error body" {
  run_zsh '
    gh-account-token() { print -r -- "test-token"; }
    gh() {
      if [[ "$1" == "api" && "$2" == "user/emails" ]]; then
        print -r -- "{\"message\":\"Not Found\",\"status\":\"404\"}"
        return 1
      fi
      if [[ "$1" == "api" && "$2" == "user" && "$4" == ".name // \"\"" ]]; then
        print -r -- "Alice A"
        return 0
      fi
      if [[ "$1" == "api" && "$2" == "user" && "$4" == ".email // \"\"" ]]; then
        print -r -- "alice@example.com"
        return 0
      fi
      return 2
    }

    _gh_account_identity "alice"
  '

  [ "$status" -eq 0 ]
  [ "$output" = $'Alice A\talice@example.com' ]
}

@test "identity rejects an error body from the profile endpoint" {
  run_zsh '
    gh-account-token() { print -r -- "test-token"; }
    gh() {
      print -r -- "{\"message\":\"Bad credentials\",\"status\":\"401\"}"
      return 1
    }

    _gh_account_identity "alice"
  '

  [ "$status" -ne 0 ]
  [ -z "$output" ]
}
