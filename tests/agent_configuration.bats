#!/usr/bin/env bats

REPO_ROOT="${BATS_TEST_DIRNAME}/.."

@test "repository instruction files stay synchronized across agents" {
  [ -f "${REPO_ROOT}/AGENTS.md" ]
  [ -f "${REPO_ROOT}/.github/workflows/AGENTS.md" ]

  [ "$(<"${REPO_ROOT}/CLAUDE.md")" = \
    $'# Claude Repository Instructions\n\n@AGENTS.md' ]
  grep -Fq '@../../.github/workflows/AGENTS.md' \
    "${REPO_ROOT}/.claude/rules/github-actions.md"

  run cmp -s \
    "${REPO_ROOT}/AGENTS.md" \
    "${REPO_ROOT}/.github/copilot-instructions.md"
  [ "$status" -eq 0 ]

  run cmp -s \
    "${REPO_ROOT}/.github/workflows/AGENTS.md" \
    <(tail -n +6 "${REPO_ROOT}/.github/instructions/actions.instructions.md")
  [ "$status" -eq 0 ]
}
