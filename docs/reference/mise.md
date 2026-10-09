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
| `node` | `lts` | Node.js runtime required by Docusaurus (`>=24.0`) |
| `bun` | `latest` | JavaScript package manager and package-script runner |
| `bats` | `latest` | bats-core test runner (for `tests/*.bats`) |
| `shellcheck` | `latest` | Shell script linter (for `install.sh`, `scripts/*.sh`) |
| `python` | `latest` | Provides a `tomllib`-capable `python3` for CI's TOML checks and `install.sh`'s JSON parsing |
| `rumdl` | `latest` | Markdown formatter and linter |

Node.js and Bun are repository-local tools, alongside lint and test tools.
`mise.lock` records resolved versions and supported platform downloads. Existing
Bun lockfiles continue to specify JavaScript dependencies; changing runtime
ownership does not update those dependencies.

`scripts/100-mise.sh` installs the tools, then installs root dependencies with
Bun using the frozen lockfile. mise has no dependency-install postinstall hook.
Documentation CI uses the same config and lock, provisioning only Node.js and
Bun before a frozen documentation dependency install.

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

For commands in a non-interactive shell, use `mise exec -- <command>` from the
repository root. For example:

```bash
mise install
mise exec -- bun run docs:install
mise exec -- bun run docs:build
```

This repository does not configure global Node.js or Bun defaults. The tracked
Zsh initialization activates mise and no longer sources Vite+ environment
files. Existing Vite+ installations and installer-written shell settings are
not removed by repository setup.

## Adding tools

```bash
# Add globally (written to ~/.config/mise/config.toml)
mise use -g python@latest

# Check tool versions
mise ls --current
```
