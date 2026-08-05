# Script list

This page explains the role and execution order of the setup scripts under `scripts/`.

## Installer entry point

`install.sh` validates `install_map.json`, creates ordinary and per-skill
links, runs the numbered setup scripts, and generates the Git SSH
`allowed_signers` file when its inputs exist.

Ordinary destinations retain the legacy conversion of a symlinked parent into
a real directory, including migration of its contents. The agent configuration
roots `~/.copilot`, `~/.codex`, and `~/.claude` are preserved when they are
valid directory symlinks so instructions are installed into the relocated
configuration tree. Invalid root links stop installation without being
removed. Legacy Copilot skill cleanup also retains the old link when a
configured whole-directory target alias resolves to the same canonical skills,
so the cleanup cannot dangle that replacement root. See
[`install_map.json`](./install-map.md) for the complete link processing rules.

## Execution order

Scripts are grouped by the numeric prefix in the file name.

| Group | Execution method | Description |
| ------------------------ | ---------------- | ----------------------------------------------- |
| `000-*` | Sequential | OS-specific initial setup |
| `001-*` | Sequential | Homebrew installation |
| `002-*` | Sequential | Brewfile package installation |
| `003-*` | Sequential | Vite+ runtime and global Bun installation |
| `100-*` (Brew-dependent) | Sequential | Configuration that depends on Homebrew packages |
| `100-*` (others) | Parallel | Independent tool configuration |

## Script details

### 000-codespace.sh

Performs Codespaces (Ubuntu)-specific initial setup. Does nothing on macOS.

- Set the time zone to `Asia/Tokyo`
- Change the default shell to zsh
- Install `build-essential` and `git`

### 001-homebrew.sh

Installs Homebrew if it is not already installed.

- macOS: `/opt/homebrew/bin/brew`
- Linux: `/home/linuxbrew/.linuxbrew/bin/brew`

After installation, it installs `gcc` and upgrades all packages with `brew upgrade`.
When invoked through `install.sh`, the script and the other setup scripts
inherit `HOMEBREW_NO_ASK=1`, so Homebrew keeps updating and installing packages
without asking for confirmation. The Homebrew installer itself also receives
`NONINTERACTIVE=1` when a new Homebrew installation is required.

### 002-brewfile.sh

Installs the packages defined in `Brewfile` with `brew bundle`.

### 003-vite-plus.sh

Installs the latest Vite+ through its official installer, enables managed
Node.js mode, sets Node.js LTS as the global default, and installs the latest
global Bun through Vite+.

This script runs before every `100-*` script, so later setup can use `vp`,
`node`, and `bun`.

### 100-gh-extensions.sh

Installs GitHub CLI extensions and adds related tools.

- Install the `gh-qwt` (`daiksud/gh-qwt`) extension (used for combined repository cloning and per-branch worktree management; see [gh-qwt](./gh-qwt.md) for details)
- Install the `gh-infra` (`babarot/gh-infra`) extension (used for declarative repository settings with `.github/settings.yml`; see [gh-infra](./gh-infra.md) for details)
- Install `fd` (a fast file search tool) with Homebrew

### 100-ghostty.sh

Installs the Ghostty terminal emulator and configures terminfo (if not already installed).

- macOS: Install from Homebrew cask
- Linux: Install with the installation script
- On macOS, copy the terminfo from `/Applications/Ghostty.app` to `~/.terminfo/` (so `xterm-ghostty` is recognized)

### 100-herdr.sh

Keeps the herdr server resident on macOS.

- Start the `herdr` background service with `brew services start herdr`

### 100-lazyvim.sh

Sets up dependencies for LazyVim (the Neovim configuration framework).

### 100-mise.sh

Installs the tools managed by mise (`mise install`).

### 100-vite-plus-project.sh

Runs a frozen Vite+ dependency install from the repository root. It resolves
the root from its own location, so it does not depend on the caller's working
directory.

### 100-sheldon.sh

Installs sheldon and starship with Homebrew, then sets up plugins according to the lockfile.

- Install `sheldon` and `starship` with Homebrew
- Install plugins with `sheldon lock`

## Brew-dependent scripts

The following scripts depend on Homebrew packages, so they are run sequentially instead of in parallel:

- `100-ghostty.sh`
- `100-lazyvim.sh`
- `100-sheldon.sh`

## Adding scripts

When adding a new script:

1. Use the next sequential prefix when the script is a prerequisite for all
   per-tool setup; otherwise create `100-<name>.sh` in `scripts/`
2. If it depends on Homebrew, add it to `is_brew_dependent_100_script()` in `install.sh`

```bash
#!/bin/bash
# scripts/100-new-tool.sh

# Tool setup process
```
