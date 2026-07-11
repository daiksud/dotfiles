#!/usr/bin/env bats
# Referential-integrity checks for install_map.json: guards against typos or
# stale entries that install.sh would silently mishandle (e.g. linking a
# source path that doesn't exist under dotfiles/).

REPO_ROOT="${BATS_TEST_DIRNAME}/.."
MAP_FILE="${REPO_ROOT}/install_map.json"

@test "install_map.json is valid JSON with a links object" {
  run jq -e '.links | type == "object"' "$MAP_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "every src entry exists under dotfiles/" {
  while IFS= read -r src; do
    [ -e "${REPO_ROOT}/dotfiles/${src}" ]
  done < <(jq -r '.links | keys[]' "$MAP_FILE")
}

@test "every dst entry is an absolute or ~-rooted path" {
  while IFS= read -r dst; do
    case "$dst" in
    "~/"* | /*) ;;
    *) return 1 ;;
    esac
  done < <(jq -r '.links | values[]' "$MAP_FILE")
}
