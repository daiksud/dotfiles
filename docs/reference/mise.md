# mise

This is the configuration reference for development tool version management with mise.

## Global settings

The global settings (`~/.config/mise/config.toml`) are not managed in dotfiles. During setup, `scripts/100-mise.sh` configures them automatically with the `mise settings` command.

```bash
# Command executed by 100-mise.sh (idempotent)
mise settings set github.credential_command "gh auth token"
```

As a result, `~/.config/mise/config.toml` becomes a machine-specific file managed by mise, and you can freely add entries such as private tools added with `mise use -g <tool>`.

### `[settings.github]`

| Key                  | Value             | Description                                             |
| -------------------- | ----------------- | ------------------------------------------------------- |
| `credential_command` | `"gh auth token"` | Use the `gh` authentication token for GitHub API access |

## Repository-local settings

### `mise.toml` (repository root)

Defines the development environment for the dotfiles repository itself.

| Tool  | Version  | Description                              |
| ----- | -------- | ---------------------------------------- |
| `bun` | `latest` | Bun runtime (for building documentation) |

The `[hooks]` section sets `postinstall = "bun install --frozen-lockfile"`, so dependencies are installed automatically after `mise install`.

### `[settings]` (`mise.toml`)

| Key            | Value  | Description                               |
| -------------- | ------ | ----------------------------------------- |
| `lockfile`     | `true` | Generate a lockfile (for reproducibility) |
| `experimental` | `true` | Enable experimental features              |

## Shell integration

Enabled in `.zshrc` via `eval "$(mise activate zsh)"`. Tool versions switch automatically on `cd` according to the project's `.mise.toml` or `.tool-versions`.

## Adding tools

```bash
# Add globally (written to ~/.config/mise/config.toml)
mise use -g python@latest

# Check tool versions
mise ls --current
```
