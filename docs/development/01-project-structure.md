# Project Structure

This page organizes the roles of the repository's main directories and files.

## Overview

```text
.
├── install.sh              # Main setup script
├── install_map.json        # Symbolic link mapping table
├── Brewfile                # Homebrew package definitions
├── dotfiles/               # Files used as symbolic link sources
├── scripts/                # Setup scripts
├── tests/                  # bats-core test suite
├── docs/                   # Docusaurus documentation
├── .devcontainer/          # GitHub Codespaces settings
├── .github/                # GitHub repository settings and workflows
├── .rumdl.toml             # Markdown formatting and linting rules
├── mise.toml               # Repository-local mise settings
├── package.json            # Documentation build scripts
└── .gitignore              # Local and generated-file exclusions
```

## Roles of the Main Files

| Path | Role | When to change it |
| ------------------ | ---------------------------------------------------------------------- | ------------------------------------------------------------- |
| `install.sh` | Entry point for setup, link creation, and script execution | When changing installation behavior |
| `install_map.json` | Mapping table for ordinary links | When adding or changing link targets |
| `dotfiles/` | Canonical personal configuration files | When changing tool settings |
| `scripts/` | Setup scripts | When changing tool installation procedures |
| `tests/` | bats-core test suite | When changing tested behavior |
| `docs/` | User and contributor documentation | When changing repository behavior |
| `.github/` | Repository settings and CI workflows | When changing GitHub integration |

## Which Files Should Be Changed Together

### When adding a new tool

1. Choose the appropriate package manager or setup script.
2. Add the canonical configuration under `dotfiles/`.
3. Add a link entry to `install_map.json` when needed.
4. Update the matching page under `docs/reference/`.

### When adding a Zsh plugin

1. Create the plugin under `dotfiles/zsh/`.
2. Update `docs/reference/zsh/plugins.md`.
3. Add a focused test when the plugin has testable non-interactive logic.

### When changing CI or tests

1. Update the workflow or test under `.github/` or `tests/`.
2. Update the relevant contributor documentation.
3. Record non-obvious architectural trade-offs in `docs/development/99-adr/`.
