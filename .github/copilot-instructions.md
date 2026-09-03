# Agent Instructions

These repository rules are shared by GitHub Copilot, Codex, and Claude Code.

## Scoped instructions

- Before editing files under `.github/workflows/`, read and follow
  `.github/workflows/AGENTS.md`.

## Commit messages

- Write in **English**
- Follow [Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>): <description>`
  - Example: `feat(starship): add SSH indicator to prompt`
  - Types: `feat`, `fix`, `docs`, `refactor`, `chore`
- Every commit requires a rationale body; a subject alone is never acceptable.
- For a non-trivial commit, write non-empty `Context:`, `Decision:`,
  `Considerations:`, and `Impact:` paragraphs. `Considerations:` records
  options, trade-offs, and risks before the decision; `Impact:` records the
  resulting constraints and follow-up work.
- A trivial dependency bump, formatter-only change, or typo fix may use a
  one- or two-sentence rationale instead, but it must still explain why the
  change was made.
- When an ADR governs the change, cite it as `ADR NNNN` rather than repeating
  its full rationale. See `docs/development/05-commit-messages.md` for the
  complete format and examples.
- Include the same rationale in every Pull Request description. Squash merges
  retain the PR body on the resulting commit, rather than the branch commits'
  bodies.
- Request Copilot Code Review with `gh api graphql` using `requestReviews(input:{pullRequestId:$pullRequestId,botIds:["BOT_kgDOCnlnWA"]})`, not `reviewerIds` or `gh pr edit --add-reviewer`.

## Documentation

Documentation uses GitHub Flavored Markdown built with Docusaurus. Place user
guides in `docs/guides/`, reference material in `docs/reference/`, contributor
documentation in `docs/development/`, and Architecture Decision Records in
`docs/development/99-adr/`.

Use the section index pages to find the right document:
`docs/guides/README.md`, `docs/reference/README.md`, and
`docs/development/README.md`.

Before editing code or documentation, read the related documentation. Before
editing documentation, read `docs/development/02-docs-style.md`. When changing
code, scripts, configuration, or tests, update the related documentation in
the same change. Record material architecture decisions and their alternatives
as ADRs.
