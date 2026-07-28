# Project Structure

This page organizes the roles of the repository's main directories and files.

## Overview

```text
.
├── AGENTS.md              # Canonical repository instructions
├── CLAUDE.md              # Claude Code adapter that imports AGENTS.md
├── install.sh              # Main setup script
├── install_map.json        # Symbolic link mapping table
├── Brewfile                # Homebrew package definitions
├── dotfiles/               # Files used as symbolic link sources
│   ├── zshrc               # -> ~/.zshrc
│   ├── zsh/                # -> ~/.zsh (custom plugins)
│   ├── tmux.conf           # -> ~/.tmux.conf
│   ├── gitconfig           # -> ~/.gitconfig
│   ├── ghostty/            # -> ~/.config/ghostty
│   ├── nvim/               # -> ~/.config/nvim (LazyVim)
│   ├── sheldon/            # -> ~/.config/sheldon
│   ├── starship.toml       # -> ~/.config/starship.toml
│   ├── skills/             # Canonical Agent Skills; linked per skill
│   ├── agent-instructions.md # Canonical personal agent instructions
│   ├── copilot-instructions.md # Legacy adapter for pre-migration links
│   └── copilot-hooks/      # Vendor-specific Copilot hooks
├── scripts/                # Setup scripts
│   ├── 000-codespace.sh
│   ├── 001-homebrew.sh
│   ├── 002-brewfile.sh
│   └── 100-*.sh
├── tests/                  # bats-core test suite (see docs/development/04-testing.md)
├── docs/                   # Documentation
│   ├── README.mdx
│   ├── guides/
│   ├── reference/
│   └── development/
├── .devcontainer/          # Codespaces settings
├── .docusaurus/            # Docusaurus site build
├── .github/
│   ├── instructions/
│   │   └── actions.instructions.md # Inline Copilot mirror of workflow guidance
│   ├── copilot-instructions.md # Inline Copilot mirror of root AGENTS.md
│   ├── dependabot.yml      # Dependency update settings for bun / GitHub Actions
│   ├── settings.yml        # Declarative repository settings managed by gh-infra
│   └── workflows/
│       ├── AGENTS.md       # Canonical GitHub Actions authoring guidance
│       ├── ci.yml          # Lint, bats tests, and a docs build check
│       └── docs.yml        # Documentation deploy (main only)
├── .claude/
│   └── rules/
│       └── github-actions.md # Claude adapter for workflow guidance
├── mise.toml               # Repository-local mise settings
├── package.json            # Scripts for building the documentation
├── .gitignore              # Definitions for untracked generated and local files
├── .editorconfig
└── LICENSE
```

## Roles of the Main Files

| Path               | Role                                                                   | When to change it                                     |
| ------------------ | ---------------------------------------------------------------------- | ----------------------------------------------------- |
| `AGENTS.md`        | Canonical repository instructions for coding agents                    | When changing repository-wide agent guidance          |
| `CLAUDE.md` | Claude import adapter for `AGENTS.md` | When the Claude import mechanism changes |
| `.github/copilot-instructions.md` | Exact inline Copilot mirror of `AGENTS.md` | Whenever repository-wide guidance changes |
| `install.sh`       | Entry point for setup. Orchestrates link creation and script execution | When changing link handling or script execution logic |
| `install_map.json` | Mapping table for ordinary links and Agent Skills targets              | When adding or changing link targets                  |
| `Brewfile`         | List of packages managed by Homebrew                                   | When adding or removing tools                         |
| `dotfiles/`        | Canonical personal configuration and agent files                       | When changing the settings for each tool              |
| `dotfiles/skills/` | Canonical Agent Skills shared across supported agents                  | When adding or changing a skill                       |
| `dotfiles/copilot-instructions.md` | Compatibility adapter for older personal Copilot links       | Only when changing or removing the migration adapter  |
| `dotfiles/copilot-hooks/` | GitHub Copilot-specific hook configuration                    | When changing the Copilot hook; do not treat it as shared agent configuration |
| `scripts/`         | Setup scripts                                                          | When changing tool installation procedures            |
| `tests/`           | bats-core test suite                                                   | When adding logic worth testing, or changing tested behavior |
| `.devcontainer/`   | Container definitions for GitHub Codespaces                            | When changing the Codespaces environment              |
| `.github/workflows/AGENTS.md` | Canonical GitHub Actions authoring guidance                  | When changing workflow authoring or action pinning guidance |
| `.github/instructions/actions.instructions.md` | Copilot frontmatter plus an exact inline mirror of workflow guidance | Whenever workflow guidance changes |
| `.claude/rules/` | Claude import adapters for path-scoped guidance | When an adapter mechanism changes |
| `.gitignore`       | Exclusion settings for files not tracked by Git                        | When adding generated files such as `node_modules/`   |

## Which Files Should Be Changed Together

### When adding a new tool

1. `Brewfile` — Add the package
2. `dotfiles/<config>` — Place the configuration file
3. `install_map.json` — Add the link entry
4. `docs/reference/tools.md` — Update the tool list
5. If needed, `scripts/100-<tool>.sh` — Add a setup script

### When adding a Zsh plugin

1. `dotfiles/zsh/<name>.zsh` — Create the plugin (`.zshrc` does not need editing; it is sourced automatically)
2. `docs/reference/zsh/plugins.md` — Update the list
3. If the plugin has logic that doesn't depend on Homebrew, network access, or fzf/interactive input, consider adding a `tests/<name>.bats` test (see [Testing](./04-testing.md))

### When adding an Agent Skill

1. `dotfiles/skills/<name>/SKILL.md` — Add the canonical, product-neutral skill
2. `docs/reference/skills.md` — Update the skill list or shared behavior reference
3. `docs/guides/06-skills.md` — Update user-facing guidance when invocation or prerequisites change
4. `docs/development/03-skills-development.md` — Update authoring guidance when the skill format or installation behavior changes

The existing `skill_targets` entry distributes new skill directories. Do not
add a full-directory `links` entry for a product-specific skill root.

### When changing agent instructions

Edit the closest canonical `AGENTS.md` for repository or path-scoped rules, or
`dotfiles/agent-instructions.md` for personal rules. Keep Claude adapters thin.
Copilot Code Review does not follow these imports, so also copy the complete
root guidance to `.github/copilot-instructions.md`, or the complete workflow
guidance after the frontmatter in
`.github/instructions/actions.instructions.md`. Run
`bats tests/agent_configuration.bats` to verify exact synchronization.

### When changing CI or tests

1. `.github/workflows/ci.yml` — Add or change a job/step
2. `tests/*.bats` — Add or change a test
3. `mise.toml` — Add any new lint/test tool so CI and local contributors share one version
4. `docs/development/04-testing.md` — Update the checks table and local run instructions
5. If the change involves a non-obvious trade-off, record it in `docs/development/99-adr/`
