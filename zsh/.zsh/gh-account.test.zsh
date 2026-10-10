#!/usr/bin/env zsh
set -e

# Run outside a Git checkout to avoid real credentials and network access.
plugin="${0:A:h}/gh-account.zsh"
tmpdir="$(mktemp -d)"
trap 'rm -rf -- "$tmpdir"' EXIT
cd "$tmpdir"
export GH_ACCOUNT_MAP_FILE="$tmpdir/repos.json"
source "$plugin" >/dev/null 2>&1

gh-account-token() { print -r -- "test-token"; }
gh() {
  if [[ "$1" == "api" && "$2" == "user/emails" ]]; then
    print -r -- '{"message":"Not Found","status":"404"}'
    return 1
  fi
  if [[ "$1" == "api" && "$2" == "user" && "$4" == '.name // ""' ]]; then
    print -r -- "Alice A"
    return 0
  fi
  if [[ "$1" == "api" && "$2" == "user" && "$4" == '.email // ""' ]]; then
    print -r -- "alice@example.com"
    return 0
  fi
  return 2
}

actual="$(_gh_account_identity alice)"
if [[ "$actual" != $'Alice A\talice@example.com' ]]; then
  print -u2 -- "FAIL: identity should fall back after email endpoint failure"
  exit 1
fi
print -r -- "ok - identity falls back when email endpoint fails"

gh() {
  print -r -- '{"message":"Bad credentials","status":"401"}'
  return 1
}

if actual="$(_gh_account_identity alice)"; then
  print -u2 -- "FAIL: identity should reject a profile endpoint error"
  exit 1
fi
if [[ -n "$actual" ]]; then
  print -u2 -- "FAIL: profile endpoint errors must not leak error bodies"
  exit 1
fi
print -r -- "ok - identity rejects profile endpoint error"
