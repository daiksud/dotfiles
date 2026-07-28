#!/usr/bin/env bats

REPO_ROOT="${BATS_TEST_DIRNAME}/.."

@test "repository instruction files stay synchronized across agents" {
  [ -f "${REPO_ROOT}/AGENTS.md" ]
  [ -f "${REPO_ROOT}/.github/workflows/AGENTS.md" ]

  [ "$(<"${REPO_ROOT}/CLAUDE.md")" = "@AGENTS.md" ]
  grep -Fq '@../../.github/workflows/AGENTS.md' \
    "${REPO_ROOT}/.claude/rules/github-actions.md"

  cmp -s \
    "${REPO_ROOT}/AGENTS.md" \
    "${REPO_ROOT}/.github/copilot-instructions.md"
  cmp -s \
    "${REPO_ROOT}/.github/workflows/AGENTS.md" \
    <(tail -n +6 "${REPO_ROOT}/.github/instructions/actions.instructions.md")
}

@test "legacy Copilot personal source forwards to canonical instructions" {
  [ -f "${REPO_ROOT}/dotfiles/agent-instructions.md" ]
  grep -Fq 'sibling `agent-instructions.md`' \
    "${REPO_ROOT}/dotfiles/copilot-instructions.md"
}
