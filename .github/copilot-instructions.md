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
