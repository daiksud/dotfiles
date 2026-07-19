#!/usr/bin/env bats

REPO_ROOT="${BATS_TEST_DIRNAME}/.."

@test "repository instruction adapters point to canonical AGENTS files" {
  [ -f "${REPO_ROOT}/AGENTS.md" ]
  [ -f "${REPO_ROOT}/.github/workflows/AGENTS.md" ]

  [ "$(<"${REPO_ROOT}/CLAUDE.md")" = "@AGENTS.md" ]
  grep -Fxq '@../AGENTS.md' \
    "${REPO_ROOT}/.github/copilot-instructions.md"
  grep -Fq '[`../workflows/AGENTS.md`](../workflows/AGENTS.md)' \
    "${REPO_ROOT}/.github/instructions/actions.instructions.md"
  grep -Fq '@../../.github/workflows/AGENTS.md' \
    "${REPO_ROOT}/.claude/rules/github-actions.md"
}

@test "legacy Copilot personal source forwards to canonical instructions" {
  [ -f "${REPO_ROOT}/dotfiles/agent-instructions.md" ]
  grep -Fq 'sibling `agent-instructions.md`' \
    "${REPO_ROOT}/dotfiles/copilot-instructions.md"
}
