# Concept

This page explains the design philosophy and policies of this dotfiles repository.

## One-command reproducibility

The highest priority is being able to reproduce a fully prepared environment—shell, editor, terminal, and CLI tools—on a new machine with a single command: `bash install.sh`.

It eliminates manual setup steps and post-installation work as much as possible by turning them into scripts.

## Declarative configuration management

- **Symbolic links** — Declare source → target in `install_map.json`
- **Agent Skills** — Keep one canonical skill directory and distribute each skill to the supported discovery roots
- **Packages** — Declare required tools in `Brewfile`
- **Plugins** — Declare Zsh plugins in `plugins.toml` (sheldon)
- **Runtimes** — Declare language versions in `config.toml` (mise)

Everything about "what to install" is written in configuration files, and the scripts only "apply the configuration files."

## One source of truth for coding agents

GitHub Copilot, Codex, and Claude Code share canonical Agent Skills and
instructions. Products that support imports use thin adapters. Copilot Code
Review requires instructions to be present directly in its recognized files,
so the repository keeps checked-in mirrors and verifies them against the
canonical files in the test suite. Hooks, manifests, and permission schemas
remain vendor-specific because the products do not share those formats.

This keeps operational and safety guidance consistent without replacing an
agent's entire skill directory. See [Using skills](./06-skills.md) and
[ADR 0013](../development/99-adr/0013-cross-agent-skills-and-instructions.md)
for the layout and rationale.

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

- Separate `GH_CONFIG_DIR` per repository
- Do not set `user.name` / `user.email` / `user.signingkey` globally
- Automatically switch to the appropriate account just by using `cd`

## Minimal external dependencies

- Does not depend on shell frameworks (such as Oh-My-Zsh)
- Separates each tool's responsibility to avoid creating a single point of failure
- Works on both macOS and Ubuntu (Codespaces)

## Idempotency

`install.sh` converges to the same result no matter how many times you run it. Even if it fails partway through, re-running it restores the correct state.
