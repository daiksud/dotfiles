# Project Structure

This page organizes the roles of the repository's main directories and files.

## Overview

```text
.
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
│   ├── skills/             # -> ~/.copilot/skills (Copilot skills)
│   └── copilot-instructions.md # -> ~/.copilot/copilot-instructions.md
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
│   ├── copilot-instructions.md
│   ├── dependabot.yml      # Dependency update settings for bun / GitHub Actions
│   ├── settings.yml        # Declarative repository settings managed by gh-infra
│   └── workflows/
│       ├── ci.yml          # Lint, bats tests, and a docs build check
│       └── docs.yml        # Documentation deploy (main only)
├── mise.toml               # Repository-local mise settings
├── package.json            # Scripts for building the documentation
├── .gitignore              # Definitions for untracked generated and local files
├── .editorconfig
└── LICENSE
```

## Roles of the Main Files

| Path               | Role                                                                   | When to change it                                     |
| ------------------ | ---------------------------------------------------------------------- | ----------------------------------------------------- |
| `install.sh`       | Entry point for setup. Orchestrates link creation and script execution | When changing link handling or script execution logic |
| `install_map.json` | Mapping table for symbolic links                                       | When adding or changing link targets                  |
| `Brewfile`         | List of packages managed by Homebrew                                   | When adding or removing tools                         |
| `dotfiles/`        | Configuration files that are symlinked                                 | When changing the settings for each tool              |
| `scripts/`         | Setup scripts                                                          | When changing tool installation procedures            |
| `tests/`           | bats-core test suite                                                   | When adding logic worth testing, or changing tested behavior |
| `.devcontainer/`   | Container definitions for GitHub Codespaces                            | When changing the Codespaces environment              |
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

### When changing CI or tests

1. `.github/workflows/ci.yml` — Add or change a job/step
2. `tests/*.bats` — Add or change a test
3. `mise.toml` — Add any new lint/test tool so CI and local contributors share one version
4. `docs/development/04-testing.md` — Update the checks table and local run instructions
5. If the change involves a non-obvious trade-off, record it in `docs/development/99-adr/`

