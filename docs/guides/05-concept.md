# Concept

This page explains the design philosophy and policies of this dotfiles repository.

## One-command reproducibility

The highest priority is being able to reproduce a fully prepared environment—shell, editor, terminal, and CLI tools—on a new machine with a single command: `bash install.sh`.

It eliminates manual setup steps and post-installation work as much as possible by turning them into scripts.

## Declarative configuration management

- **Symbolic links** — Declare source → target in `install_map.json`
- **Packages** — Declare required tools in `Brewfile`
- **Plugins** — Declare Zsh plugins in `plugins.toml` (sheldon)
- **Runtimes** — Declare language versions in `config.toml` (mise)

Everything about "what to install" is written in configuration files, and the scripts only "apply the configuration files."

## Use Tokyo Night Storm consistently as the theme

All tools use **Tokyo Night Storm** as the unified color scheme.

| Tool     | Configuration                                              |
| -------- | ---------------------------------------------------------- |
| Ghostty  | `theme = TokyoNight Storm`                                 |
| Neovim   | `tokyonight.nvim` (style = `"storm"`, transparent)         |
| tmux     | `tokyo-night-tmux` (theme = `storm`)                       |
| Starship | Custom formatting matched to the Tokyo Night Storm palette |

This creates a visually consistent environment without color discontinuities between the terminal, tmux, and editor.

## Multi-account support

It is designed on the assumption that you use multiple GitHub accounts.

- Separate `GH_CONFIG_DIR` per repository
- Do not set `user.name` / `user.email` / `user.signingkey` globally
- Automatically switch to the appropriate account just by using `cd`

## Minimal external dependencies

- Does not depend on shell frameworks (such as Oh-My-Zsh)
- Separates each tool's responsibility to avoid creating a single point of failure
- Works on both macOS and Ubuntu (Codespaces)

## Idempotency

`install.sh` converges to the same result no matter how many times you run it. Even if it fails partway through, re-running it restores the correct state.
