#!/usr/bin/env bats

# Behavior coverage for dotfiles/zsh/gh-account.zsh.
#
# The plugin is Zsh-only, so every case loads it in a non-interactive `zsh -c`
# subshell. That subshell also proves the chpwd hook never prompts when the
# shell is not interactive.

PLUGIN="${BATS_TEST_DIRNAME}/../dotfiles/zsh/gh-account.zsh"

setup() {
  TEST_TMP="$(mktemp -d)"
  export TEST_TMP
  export MAP_FILE="${TEST_TMP}/repos.json"
}

teardown() {
  [ -n "${TEST_TMP:-}" ] && rm -rf "$TEST_TMP"
}

# Load the plugin with a scratch mapping file and run Zsh code against it.
# `gh-account-sync` runs at load time, so its output is discarded here.
run_zsh() {
  run zsh -c "
    export GH_ACCOUNT_MAP_FILE='${MAP_FILE}'
    source '${PLUGIN}' >/dev/null 2>&1
    $1
  "
}

@test "the plugin parses as valid Zsh" {
  run zsh -n "$PLUGIN"
  [ "$status" -eq 0 ]
}

@test "github.com is always considered a known host" {
  # github.com must stay usable even when gh has no stored authentication
  # yet (for example a fresh CI runner), unlike an arbitrary Enterprise host.
  run_zsh '
    _gh_account_host_is_known "github.com" && print -r -- known || print -r -- unknown
  '
  [ "$status" -eq 0 ]
  [ "$output" = "known" ]
}

@test "remote URLs normalize to a lowercase host/owner/repo identity" {
  run_zsh '
    for url in \
      "https://github.com/owner/repo.git" \
      "https://github.com/owner/repo" \
      "https://GitHub.com/Owner/Repo.git" \
      "git@github.com:owner/repo.git" \
      "ssh://git@github.com/owner/repo.git" \
      "ssh://git@github.com:22/owner/repo.git" \
      "git://github.com/owner/repo" \
      "https://ghe.example.com/owner/repo.git"; do
      gh-account-repo-id "$url"
    done
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "github.com/owner/repo" ]
  [ "${lines[1]}" = "github.com/owner/repo" ]
  [ "${lines[2]}" = "github.com/owner/repo" ]
  [ "${lines[3]}" = "github.com/owner/repo" ]
  [ "${lines[4]}" = "github.com/owner/repo" ]
  [ "${lines[5]}" = "github.com/owner/repo" ]
  [ "${lines[6]}" = "github.com/owner/repo" ]
  [ "${lines[7]}" = "ghe.example.com/owner/repo" ]
}

@test "unusable remote URLs are rejected" {
  run_zsh '
    for url in "" "not-a-url" "https://github.com/owner"; do
      gh-account-repo-id "$url" && print "ACCEPTED: $url"
    done
    print done
  '
  [ "$status" -eq 0 ]
  [ "$output" = "done" ]
}

@test "repository identities derive a host-qualified owner identity" {
  run_zsh '
    _gh_account_owner_id "github.com/owner/repo"
    _gh_account_owner_id "ghe.example.com/Owner/Repo"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "github.com/owner" ]
  [ "${lines[1]}" = "ghe.example.com/Owner" ]
}

@test "invalid repository identities do not derive an owner identity" {
  run_zsh '
    for id in "" "github.com" "github.com/owner" "github.com/owner/repo/extra"; do
      _gh_account_owner_id "$id" && print "ACCEPTED: $id"
    done
    print done
  '
  [ "$status" -eq 0 ]
  [ "$output" = "done" ]
}

@test "the mapping file is created and read back" {
  [ ! -f "$MAP_FILE" ]

  run_zsh '
    gh-account-map-set "github.com/owner/repo" "alice" "Alice A" "alice@example.com"
    gh-account-map-get "github.com/owner/repo" login
    gh-account-map-get "github.com/owner/repo" name
    gh-account-map-get "github.com/owner/repo" email
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "alice" ]
  [ "${lines[1]}" = "Alice A" ]
  [ "${lines[2]}" = "alice@example.com" ]

  [ -f "$MAP_FILE" ]
  jq -e . "$MAP_FILE" >/dev/null
}

@test "updating one entry preserves the others" {
  run_zsh '
    gh-account-map-set "github.com/owner/one" "alice" "Alice A" "alice@example.com"
    gh-account-map-set "github.com/owner/two" "bob" "Bob B" "bob@example.com"
    gh-account-map-set "github.com/owner/one" "carol" "Carol C" "carol@example.com"
    gh-account-map-get "github.com/owner/one" login
    gh-account-map-get "github.com/owner/two" login
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "carol" ]
  [ "${lines[1]}" = "bob" ]
}

@test "an unknown key reports failure without output" {
  run_zsh 'gh-account-map-get "github.com/owner/missing" login'
  [ "$status" -ne 0 ]
  [ -z "$output" ]
}

@test "forgetting one entry keeps the others" {
  run_zsh '
    gh-account-map-set "github.com/owner/one" "alice" "Alice A" "alice@example.com"
    gh-account-map-set "github.com/owner/two" "bob" "Bob B" "bob@example.com"
    gh-account-map-unset "github.com/owner/one"
    gh-account-map-get "github.com/owner/one" login || print "one: removed"
    gh-account-map-get "github.com/owner/two" login
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "one: removed" ]
  [ "${lines[1]}" = "bob" ]
}

@test "repository mappings override owner defaults" {
  run_zsh '
    gh-account-map-set "github.com/owner" "alice" "Alice A" "alice@example.com"
    _gh_account_mapping_id "github.com/owner/repo"
    gh-account-map-set "github.com/owner/repo" "bob" "Bob B" "bob@example.com"
    _gh_account_mapping_id "github.com/owner/repo"
    _gh_account_mapping_id "github.com/other/repo" || print "other: missing"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "github.com/owner" ]
  [ "${lines[1]}" = "github.com/owner/repo" ]
  [ "${lines[2]}" = "other: missing" ]
}

@test "owner defaults stay separate by host" {
  run_zsh '
    gh-account-map-set "github.com/owner" "alice" "Alice A" "alice@example.com"
    gh-account-map-set "ghe.example.com/owner" "bob" "Bob B" "bob@example.com"
    _gh_account_mapping_id "github.com/owner/repo"
    _gh_account_mapping_id "ghe.example.com/owner/repo"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "github.com/owner" ]
  [ "${lines[1]}" = "ghe.example.com/owner" ]
}

@test "the identity is injected without replacing the caller Copilot token" {
  run_zsh '
    export COPILOT_GITHUB_TOKEN=caller-token
    gh-account-token() { print -r -- "test-token"; }
    _gh_account_apply "github.com/owner/repo" "nosuchaccount" "Alice A" "alice@example.com" 2>/dev/null
    print -r -- "count=$GIT_CONFIG_COUNT"
    print -r -- "k0=$GIT_CONFIG_KEY_0 v0=$GIT_CONFIG_VALUE_0"
    print -r -- "k1=$GIT_CONFIG_KEY_1 v1=$GIT_CONFIG_VALUE_1"
    print -r -- "gh=$GH_TOKEN copilot=$COPILOT_GITHUB_TOKEN"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "count=2" ]
  [ "${lines[1]}" = "k0=user.name v0=Alice A" ]
  [ "${lines[2]}" = "k1=user.email v1=alice@example.com" ]
  [ "${lines[3]}" = "gh=test-token copilot=caller-token" ]
}

@test "a present signing key adds a third configuration entry" {
  run_zsh '
    export HOME="'"${TEST_TMP}"'"
    mkdir -p "$HOME/.ssh"
    print -r -- "ssh-ed25519 AAAATEST test@example.com" > "$HOME/.ssh/keyowner.pub"
    gh-account-token() { print -r -- "test-token"; }
    _gh_account_apply "github.com/owner/repo" "keyowner" "Alice A" "alice@example.com" 2>/dev/null
    print -r -- "count=$GIT_CONFIG_COUNT"
    print -r -- "k2=$GIT_CONFIG_KEY_2 v2=$GIT_CONFIG_VALUE_2"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "count=3" ]
  [ "${lines[1]}" = "k2=user.signingkey v2=${TEST_TMP}/.ssh/keyowner.pub" ]

  grep -Fq "alice@example.com ssh-ed25519 AAAATEST" "${TEST_TMP}/.ssh/allowed_signers"
}

@test "the missing-signing-key warning is suppressed in a non-interactive shell" {
  run_zsh '
    gh-account-token() { print -r -- "test-token"; }
    _gh_account_apply "github.com/owner/repo" "nosuchaccount" "Alice A" "alice@example.com"
  '
  [ "$status" -eq 0 ]
  [[ "$output" != *"signing key not found"* ]]
}

@test "clearing removes only variables the plugin exported" {
  run_zsh '
    export COPILOT_GITHUB_TOKEN=caller-token
    gh-account-token() { print -r -- "test-token"; }
    _gh_account_apply "github.com/owner/repo" "nosuchaccount" "Alice A" "alice@example.com" 2>/dev/null
    _gh_account_clear_env
    print -r -- "count=${GIT_CONFIG_COUNT:-unset}"
    print -r -- "k0=${GIT_CONFIG_KEY_0:-unset} v0=${GIT_CONFIG_VALUE_0:-unset}"
    print -r -- "k1=${GIT_CONFIG_KEY_1:-unset} v1=${GIT_CONFIG_VALUE_1:-unset}"
    print -r -- "gh=${GH_TOKEN:-unset} copilot=${COPILOT_GITHUB_TOKEN:-unset} config=${GH_CONFIG_DIR:-unset}"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "count=unset" ]
  [ "${lines[1]}" = "k0=unset v0=unset" ]
  [ "${lines[2]}" = "k1=unset v1=unset" ]
  [ "${lines[3]}" = "gh=unset copilot=caller-token config=unset" ]
}

@test "syncing outside a Git repository clears only plugin-owned variables" {
  run_zsh '
    cd "'"${TEST_TMP}"'"
    export GH_TOKEN=stale
    export COPILOT_GITHUB_TOKEN=caller-token
    export GH_CONFIG_DIR=/stale
    gh-account-sync
    print -r -- "gh=${GH_TOKEN:-unset} copilot=${COPILOT_GITHUB_TOKEN:-unset} config=${GH_CONFIG_DIR:-unset}"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "gh=unset copilot=caller-token config=unset" ]
}

@test "syncing a non-GitHub remote clears only plugin-owned variables" {
  git init -q "${TEST_TMP}/other"
  git -C "${TEST_TMP}/other" remote add origin "https://gitlab.example.com/owner/repo.git"

  run_zsh '
    cd "'"${TEST_TMP}"'/other"
    export GH_TOKEN=stale
    export COPILOT_GITHUB_TOKEN=caller-token
    gh-account-sync
    print -r -- "gh=${GH_TOKEN:-unset} copilot=${COPILOT_GITHUB_TOKEN:-unset}"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "gh=unset copilot=caller-token" ]
}

@test "a mapped repository on an Enterprise host is applied when gh knows that host" {
  # Regression test: the previous host filter only matched literal
  # "github.com", "*.github.com", or "*ghe.com" suffixes, which excludes
  # realistic GitHub Enterprise Server hostnames such as this one even though
  # gh-account-repo-id normalizes them correctly.
  git init -q "${TEST_TMP}/repo"
  git -C "${TEST_TMP}/repo" remote add origin "https://git.example-enterprise.com/owner/repo.git"

  run_zsh '
    _gh_account_host_is_known() { [ "$1" = "git.example-enterprise.com" ]; }
    gh-account-map-set "git.example-enterprise.com/owner/repo" "alice" "Alice A" "alice@example.com" >/dev/null
    gh-account-token() { print -r -- "test-token"; }
    cd "'"${TEST_TMP}"'/repo" 2>/dev/null
    print -r -- "gh=${GH_TOKEN:-unset}"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "gh=test-token" ]
}

@test "an unmapped repository never prompts in a non-interactive shell" {
  git init -q "${TEST_TMP}/repo"
  git -C "${TEST_TMP}/repo" remote add origin "https://github.com/owner/unmapped.git"

  run_zsh '
    cd "'"${TEST_TMP}"'/repo"
    gh-account-sync
    print -r -- "gh=${GH_TOKEN:-unset} count=${GIT_CONFIG_COUNT:-unset}"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "gh=unset count=unset" ]
  [ ! -f "$MAP_FILE" ]
}

@test "a mapped repository is applied by the chpwd hook" {
  git init -q "${TEST_TMP}/repo"
  git -C "${TEST_TMP}/repo" remote add origin "git@github.com:Owner/Mapped.git"

  run_zsh '
    gh-account-map-set "github.com/owner/mapped" "alice" "Alice A" "alice@example.com" >/dev/null
    gh-account-token() { print -r -- "test-token"; }
    cd "'"${TEST_TMP}"'/repo" 2>/dev/null
    print -r -- "gh=${GH_TOKEN:-unset}"
    print -r -- "name=$(git config user.name) email=$(git config user.email)"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "gh=test-token" ]
  [ "${lines[1]}" = "name=Alice A email=alice@example.com" ]
}

@test "an owner default applies to every repository for that owner" {
  git init -q "${TEST_TMP}/one"
  git init -q "${TEST_TMP}/two"
  git -C "${TEST_TMP}/one" remote add origin "https://github.com/owner/one.git"
  git -C "${TEST_TMP}/two" remote add origin "https://github.com/owner/two.git"

  run_zsh '
    gh-account-map-set "github.com/owner" "alice" "Alice A" "alice@example.com" >/dev/null
    gh-account-token() { print -r -- "test-token"; }
    cd "'"${TEST_TMP}"'/one" 2>/dev/null
    print -r -- "one=$GH_TOKEN applied=$_GH_ACCOUNT_APPLIED_REPO_ID"
    cd "'"${TEST_TMP}"'/two" 2>/dev/null
    print -r -- "two=$GH_TOKEN applied=$_GH_ACCOUNT_APPLIED_REPO_ID"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "one=test-token applied=github.com/owner/one" ]
  [ "${lines[1]}" = "two=test-token applied=github.com/owner/two" ]
}

@test "selection defaults to owner and accepts an explicit owner scope" {
  git init -q "${TEST_TMP}/repo"
  git -C "${TEST_TMP}/repo" remote add origin "https://github.com/owner/repo.git"

  run_zsh '
    gh-account-logins() { print -r -- "alice"; }
    fzf() { print -r -- "alice"; }
    _gh_account_identity() { printf "Alice A\talice@example.com\n"; }
    gh-account-token() { print -r -- "token-$1"; }
    cd "'"${TEST_TMP}"'/repo" 2>/dev/null
    gh-account-select
    print -r -- "default=$(gh-account-map-get "github.com/owner" login)"
    gh-account-map-unset "github.com/owner"
    gh-account-select --owner
    print -r -- "explicit=$(gh-account-map-get "github.com/owner" login)"
    gh-account-map-get "github.com/owner/repo" login || print -r -- "repo=unset"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "default=alice" ]
  [ "${lines[1]}" = "explicit=alice" ]
  [ "${lines[2]}" = "repo=unset" ]
}

@test "repository selection creates an override over the owner default" {
  git init -q "${TEST_TMP}/repo"
  git -C "${TEST_TMP}/repo" remote add origin "https://github.com/owner/repo.git"

  run_zsh '
    gh-account-map-set "github.com/owner" "alice" "Alice A" "alice@example.com" >/dev/null
    gh-account-logins() { print -r -- "bob"; }
    fzf() { print -r -- "bob"; }
    _gh_account_identity() { printf "Bob B\tbob@example.com\n"; }
    gh-account-token() { print -r -- "token-$1"; }
    cd "'"${TEST_TMP}"'/repo" 2>/dev/null
    gh-account-select --repo
    print -r -- "owner=$(gh-account-map-get "github.com/owner" login)"
    print -r -- "repo=$(gh-account-map-get "github.com/owner/repo" login)"
    print -r -- "gh=$GH_TOKEN"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "owner=alice" ]
  [ "${lines[1]}" = "repo=bob" ]
  [ "${lines[2]}" = "gh=token-bob" ]
}

@test "owner selection keeps a repository override active" {
  git init -q "${TEST_TMP}/repo"
  git -C "${TEST_TMP}/repo" remote add origin "https://github.com/owner/repo.git"

  run_zsh '
    gh-account-map-set "github.com/owner" "alice" "Alice A" "alice@example.com" >/dev/null
    gh-account-map-set "github.com/owner/repo" "bob" "Bob B" "bob@example.com" >/dev/null
    gh-account-logins() { print -r -- "carol"; }
    fzf() { print -r -- "carol"; }
    _gh_account_identity() { printf "Carol C\tcarol@example.com\n"; }
    gh-account-token() { print -r -- "token-$1"; }
    cd "'"${TEST_TMP}"'/repo" 2>/dev/null
    gh-account-select --owner
    print -r -- "owner=$(gh-account-map-get "github.com/owner" login)"
    print -r -- "repo=$(gh-account-map-get "github.com/owner/repo" login)"
    print -r -- "gh=$GH_TOKEN"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "owner=carol" ]
  [ "${lines[1]}" = "repo=bob" ]
  [ "${lines[2]}" = "gh=token-bob" ]
}

@test "forgetting each scope preserves its valid fallback" {
  git init -q "${TEST_TMP}/repo"
  git -C "${TEST_TMP}/repo" remote add origin "https://github.com/owner/repo.git"

  run_zsh '
    gh-account-map-set "github.com/owner" "alice" "Alice A" "alice@example.com" >/dev/null
    gh-account-map-set "github.com/owner/repo" "bob" "Bob B" "bob@example.com" >/dev/null
    gh-account-token() { print -r -- "token-$1"; }
    cd "'"${TEST_TMP}"'/repo" 2>/dev/null
    gh-account-select --repo --forget >/dev/null
    print -r -- "after-repo=$GH_TOKEN"
    gh-account-map-set "github.com/owner/repo" "bob" "Bob B" "bob@example.com" >/dev/null
    gh-account-select --forget >/dev/null
    print -r -- "after-owner=$GH_TOKEN"
    gh-account-select --repo --forget >/dev/null
    print -r -- "after-both=${GH_TOKEN:-unset}"
  '
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "after-repo=token-alice" ]
  [ "${lines[1]}" = "after-owner=token-bob" ]
  [ "${lines[2]}" = "after-both=unset" ]
}

@test "selection rejects conflicting and unknown options" {
  run_zsh 'gh-account-select --owner --repo'
  [ "$status" -eq 2 ]
  [[ "$output" == *"choose either --owner or --repo"* ]]
  [[ "$output" == *"usage: gh-account-select [--owner | --repo] [--forget]"* ]]

  run_zsh 'gh-account-select --invalid'
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown option '--invalid'"* ]]
  [[ "$output" == *"usage: gh-account-select [--owner | --repo] [--forget]"* ]]
}

@test "environment configuration overrides leftover local identity" {
  git init -q "${TEST_TMP}/repo"
  git -C "${TEST_TMP}/repo" remote add origin "https://github.com/owner/mapped.git"
  git -C "${TEST_TMP}/repo" config --local user.name "Stale Name"
  git -C "${TEST_TMP}/repo" config --local user.email "stale@example.com"

  run_zsh '
    gh-account-map-set "github.com/owner/mapped" "alice" "Alice A" "alice@example.com" >/dev/null
    gh-account-token() { print -r -- "test-token"; }
    cd "'"${TEST_TMP}"'/repo" 2>/dev/null
    print -r -- "name=$(git config user.name) email=$(git config user.email)"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "name=Alice A email=alice@example.com" ]
}
