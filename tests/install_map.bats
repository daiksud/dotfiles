#!/usr/bin/env bats
# Referential-integrity checks for install_map.json: guards against typos or
# stale entries that install.sh would silently mishandle (e.g. linking a
# source path that doesn't exist under dotfiles/).

REPO_ROOT="${BATS_TEST_DIRNAME}/.."
MAP_FILE="${REPO_ROOT}/install_map.json"

@test "install_map.json is valid JSON with a links object" {
  run jq -e '
    (.links | type == "object") and
    (all(.links[];
      (type == "string") or
      (type == "array" and all(.[]; type == "string"))
    ))
  ' "$MAP_FILE"
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
    \~/* | /*) ;;
    *) return 1 ;;
    esac
  done < <(jq -r '.links | values[] | if type == "array" then .[] else . end' "$MAP_FILE")
}

@test "agent instructions are shared with Copilot, Codex, and Claude Code" {
  run jq -e '
    .links["agent-instructions.md"] as $targets |
    ($targets | type == "array") and
    ([
      "~/.copilot/copilot-instructions.md",
      "~/.codex/AGENTS.md",
      "~/.claude/CLAUDE.md"
    ] - $targets | length == 0)
  ' "$MAP_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "skill_targets is an array of absolute or ~-rooted paths" {
  run jq -e '
    (.skill_targets | type == "array" and length > 0) and
    all(.skill_targets[]; type == "string") and
    (["~/.agents/skills", "~/.claude/skills"] - .skill_targets | length == 0)
  ' "$MAP_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]

  while IFS= read -r target; do
    case "$target" in
    \~/* | /*) ;;
    *) return 1 ;;
    esac
  done < <(jq -r '.skill_targets[]' "$MAP_FILE")
}
