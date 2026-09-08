# Concept

This page explains the design philosophy and policies of this dotfiles repository.

## One-command reproducibility

The highest priority is being able to reproduce a fully prepared environment—shell, editor, terminal, and CLI tools—on a new machine with a single command: `bash install.sh`.

It eliminates manual setup steps and post-installation work as much as possible by turning them into scripts.

## Declarative configuration management

- **Symbolic links** — Declare source → target in `install_map.json`
- **Packages** — Declare general tools in `Brewfile`
- **Plugins** — Declare Zsh plugins in `plugins.toml` (sheldon)
- **JavaScript toolchain** — Let Vite+ manage Node.js and Bun
- **Development tools** — Declare repository lint and test tools in `mise.toml`

Everything about "what to install" is written in configuration files or the
dedicated Vite+ setup script, and the scripts apply those declarations.

## Use Tokyo Night Storm consistently as the theme

All tools use **Tokyo Night Storm** as the unified color scheme.

| Tool | Theme behavior |
| ---------------------------------------------- | --------------------------------------------------- |
| [Ghostty](../reference/ghostty.md) | Uses the Tokyo Night Storm theme |
| [Neovim](../reference/nvim.md) | Uses Tokyo Night Storm with transparent backgrounds |
| [herdr](../reference/herdr.md) | Uses the built-in `tokyo-night` theme |
| [Starship](../reference/starship.md) | Uses a custom Tokyo Night Storm-compatible palette |

This creates a visually consistent environment without color discontinuities between the terminal, herdr, and editor.

## Multi-account support

It is designed on the assumption that you use multiple GitHub accounts.

- One default account per GitHub owner, with repository-specific overrides
  recorded in a central mapping file
- Do not set `user.name` / `user.email` / `user.signingkey` globally
- Automatically switch to the appropriate account just by using `cd`

The selected account is applied through the shell-scoped `gh-account.zsh` plugin and the repository mapping file.

## Minimal external dependencies

- Does not depend on shell frameworks (such as Oh-My-Zsh)
- Separates each tool's responsibility to avoid creating a single point of failure
- Works on both macOS and Ubuntu (Codespaces)

## Idempotency

`install.sh` converges to the same result no matter how many times you run it. Even if it fails partway through, re-running it restores the correct state.
