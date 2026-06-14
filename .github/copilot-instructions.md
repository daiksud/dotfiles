# Copilot Instructions

## Commit messages

- Write in **English**
- Follow [Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>): <description>`
  - Example: `feat(starship): add SSH indicator to prompt`
  - Types: `feat`, `fix`, `docs`, `refactor`, `chore`

## Documentation structure

Under `docs/`, place GitHub Flavored Markdown documentation built with Docusaurus:

- `docs/guides/` — user guides (setup and usage)
- `docs/reference/` — reference (tool list, configuration specs)
- `docs/development/` — contributor information (structure, style guide)
- `docs/development/99-adr/` — Architecture Decision Records

### Documentation mapping table

| Topic              | Path                                        | Audience     |
| ------------------ | ------------------------------------------- | ------------ |
| Quick start        | `docs/guides/01-quick-start.md`             | Users        |
| Installation       | `docs/guides/02-installation.md`            | Users        |
| Link management    | `docs/guides/03-managing-links.md`          | Users        |
| Git identity       | `docs/guides/04-git-identity.md`            | Users        |
| How to use skills  | `docs/guides/06-skills.md`                  | Users        |
| Ghostty            | `docs/reference/ghostty.md`                 | Users        |
| Git                | `docs/reference/git.md`                     | Users        |
| mise               | `docs/reference/mise.md`                    | Users        |
| Neovim             | `docs/reference/nvim.md`                    | Users        |
| RTK                | `docs/reference/rtk.md`                     | Users        |
| Sheldon            | `docs/reference/sheldon.md`                 | Users        |
| Starship           | `docs/reference/starship.md`                | Users        |
| tmux               | `docs/reference/tmux.md`                    | Users        |
| Zsh                | `docs/reference/zsh/README.md`              | Users        |
| Zsh plugins        | `docs/reference/zsh/plugins.md`             | Users        |
| install_map.json   | `docs/reference/install-map.md`             | Users        |
| gh-infra           | `docs/reference/gh-infra.md`                | Users        |
| Scripts            | `docs/reference/scripts.md`                 | Users        |
| Tools (Brewfile)   | `docs/reference/tools.md`                   | Users        |
| Copilot Skills     | `docs/reference/skills.md`                  | Users        |
| Project structure  | `docs/development/01-project-structure.md`  | Contributors |
| Docs style         | `docs/development/02-docs-style.md`         | Contributors |
| ADR index          | `docs/development/99-adr/README.md`         | Contributors |
| Skills development | `docs/development/03-skills-development.md` | Contributors |

Style reference to read before editing:

- `docs/development/02-docs-style.md` — documentation writing style guide

## Required workflow

1. Before editing code, always read the related documents under `docs/` (at minimum, the relevant section `README` and related pages).
2. Before editing documentation, always read `docs/development/02-docs-style.md` to understand the documentation policy and conventions.
3. When changing code, scripts, or configuration, always update `docs/` in the same change. For the change checklist and scope mapping, refer to the "Documentation Strategy" section of `docs/development/02-docs-style.md`.
4. After making changes, always verify documentation accuracy, link integrity, and coverage against the current implementation.
5. If the current document structure is hard to understand, reorganize it as needed.
6. Always keep documentation aligned with the current implementation. Do not defer updates to a later commit.
7. If there are multiple options for architecture or technical choices, always record them in `docs/development/99-adr/`.

## Docusaurus conventions

- Add a numeric prefix in the `01-` format to filenames for sidebar ordering
- Do not add numeric prefixes to section directories (`guides/`, `reference/`, `development/`)
- Use each directory's `README.md` as the index page
- Write links as relative paths with the `.md` extension
- Start each page with a `# h1` title, followed by an explanatory paragraph

## Required quality standards

- Documentation must always state **what changed**, **why it changed**, and **how to operate it**
- Make examples and commands ready to copy and use as-is
- Avoid outdated guidance and duplicated guidance
- Include clear reasons in records of decisions
