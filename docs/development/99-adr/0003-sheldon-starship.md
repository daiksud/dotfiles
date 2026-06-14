# ADR 0003: Replace Oh-My-Zsh with Sheldon + Starship

## Status

Accepted

## Context

Oh-My-Zsh is a monolithic framework that bundles plugin management, themes, and completion. It had the following problems:

- Shell startup was slow because the entire framework (`lib/*.zsh`) had to be loaded
- Plugin management depended on OMZ's directory structure and was not declarative
- Themes depended on internal OMZ functions and could not be ported to other shells

The goal is to achieve fast startup, declarative and minimal plugin management, and a portable prompt.

## Decision

Replace Oh-My-Zsh with two specialized tools:

- **Sheldon** — a declarative plugin manager configured with TOML (`~/.config/sheldon/plugins.toml`)
- **Starship** — a Rust-based cross-shell prompt (`~/.config/starship.toml`)

### Plugin loading

Declare only the required plugins in `plugins.toml`. Continue using the OMZ git plugin by directly referencing the `plugins/git` directory in the `ohmyzsh/ohmyzsh` repository.

### Important constraint: `compinit` order

`compinit` must be called **before** `sheldon source`. This is required so plugins that use `compdef`, such as fzf-tab, work correctly.

## Alternatives Considered

### Keep Oh-My-Zsh

Not adopted — unnecessary overhead and non-declarative plugin management.

### Zinit / Antidote

Considered — both are strong zsh plugin managers. Sheldon was chosen because of its Rust implementation (fast), TOML configuration (readable), and lockfile mechanism.

### Pure / Powerlevel10k

Considered as prompts — Starship was chosen because of its cross-shell compatibility and simple TOML configuration.

## Consequences

- Shell startup is faster because only declared plugins are loaded
- `plugins.toml` becomes the single source of truth for zsh plugins
- Starship configuration can be reused in other shells such as bash and fish
- The OMZ plugins for Brew, gh, and mise are removed because those tools provide their own shell integrations
