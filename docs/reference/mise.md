# mise

This is the configuration reference for development tool version management with mise.

## Global settings

The global settings (`~/.config/mise/config.toml`) are not managed in dotfiles.
During setup,
[`scripts/100-mise.sh`](https://github.com/daiksud/dotfiles/blob/main/scripts/100-mise.sh)
uses `mise settings` to configure GitHub credential lookup through the
authenticated `gh` session.

As a result, `~/.config/mise/config.toml` becomes a machine-specific file managed by mise, and you can freely add entries such as private tools added with `mise use -g <tool>`.

### `[settings.github]`

| Key | Description |
| -------------------- | ----------------------------------------------------------------- |
| `credential_command` | Ask the authenticated `gh` session for GitHub API credentials |

## Repository-local settings

### `mise.toml` (repository root)

Defines the development environment for the dotfiles repository itself.

| Tool | Version | Description |
| ------------ | -------- | ----------------------------------------------------- |
| `bun` | `latest` | Bun runtime (for building documentation) |
| `bats` | `latest` | bats-core test runner (for `tests/*.bats`) |
| `shellcheck` | `latest` | Shell script linter (for `install.sh`, `scripts/*.sh`) |
| `python` | `latest` | Provides a `tomllib`-capable `python3` for CI's TOML checks and `install.sh`'s JSON parsing |
| `rumdl` | `0.2.44` | Markdown formatter and linter |

The `[hooks]` section sets `postinstall = "bun install --frozen-lockfile"`, so dependencies are installed automatically after `mise install`.

The repository also exposes `markdown:format` and `markdown:lint` tasks so
contributors and CI use the same rumdl commands. For how the tools are used in
CI and how to run the same checks locally, see
[Testing](../development/04-testing.md).

### `[settings]` (`mise.toml`)

| Key | Value | Description |
| -------------- | ------ | ----------------------------------------- |
| `lockfile` | `true` | Generate a lockfile (for reproducibility) |
| `experimental` | `true` | Enable experimental features |

## Shell integration

The tracked
[`dotfiles/zshrc`](https://github.com/daiksud/dotfiles/blob/main/dotfiles/zshrc)
activates mise when Zsh starts. Tool versions then switch automatically on
`cd` according to the project's `.mise.toml` or `.tool-versions`.

## Adding tools

```bash
# Add globally (written to ~/.config/mise/config.toml)
mise use -g python@latest

# Check tool versions
mise ls --current
```
