# Copilot Instructions

## Commit messages

- Write in **English**
- Follow **Conventional Commits**: `<type>(<scope>): <description>`
  - Example: `feat(starship): add SSH indicator to prompt`
  - Types: `feat`, `fix`, `docs`, `refactor`, `chore`

## Documentation structure

Documentation lives under `docs/` as GitHub Flavored Markdown files, built with Docusaurus:

- `docs/guides/` — User guides (setup and usage)
- `docs/reference/` — Reference (tool lists, config specs)
- `docs/development/` — Contributor info (structure, style guide)
- `docs/development/99-adr/` — Architecture Decision Records

### Documentation Map

| Topic | Path | Audience |
|-------|------|----------|
| Quick start | `docs/guides/01-quick-start.md` | Users |
| Installation | `docs/guides/02-installation.md` | Users |
| Managing links | `docs/guides/03-managing-links.md` | Users |
| Git identity | `docs/guides/04-git-identity.md` | Users |
| Ghostty | `docs/reference/ghostty.md` | Users |
| Git | `docs/reference/git.md` | Users |
| mise | `docs/reference/mise.md` | Users |
| Neovim | `docs/reference/nvim.md` | Users |
| Sheldon | `docs/reference/sheldon.md` | Users |
| Starship | `docs/reference/starship.md` | Users |
| tmux | `docs/reference/tmux.md` | Users |
| Zsh | `docs/reference/zsh/README.md` | Users |
| Zsh plugins | `docs/reference/zsh/plugins.md` | Users |
| install_map.json | `docs/reference/install-map.md` | Users |
| Scripts | `docs/reference/scripts.md` | Users |
| Tools (Brewfile) | `docs/reference/tools.md` | Users |
| Project structure | `docs/development/01-project-structure.md` | Contributors |
| Docs style | `docs/development/02-docs-style.md` | Contributors |
| ADR index | `docs/development/99-adr/README.md` | Contributors |

Key style references (read before editing docs):

- `docs/development/02-docs-style.md` — Documentation writing style guide

## Mandatory workflow

1. Before editing code, always read relevant documents under `docs/` (at minimum the section README and related pages).
2. When changing code, scripts, or configuration, always update `docs/` in the same change.
3. If the current document structure reduces clarity, reorganize docs as needed.
4. Keep documentation accurate to the current implementation.
5. If an architecture or technology choice is made from multiple options, always record it in `docs/development/99-adr/`.

## Docusaurus conventions

- File names use `01-` style numeric prefixes for sidebar ordering.
- Section directories (`guides/`, `reference/`, `development/`) do **not** use numeric prefixes.
- `README.md` in each directory serves as the index page.
- Links must use relative paths with `.md` extension.
- Each page starts with an `# h1` title, followed by a description paragraph.

## Required quality bar

- Documentation must explain **what changed**, **why**, and **how to operate it**.
- Examples and commands must be copy-paste ready.
- Avoid stale or duplicated guidance.
- Decision records must include explicit rationale.
