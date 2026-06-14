# Script list

This page explains the role and execution order of the setup scripts under `scripts/`.

## Execution order

Scripts are grouped by the numeric prefix in the file name.

| Group                    | Execution method | Description                                     |
| ------------------------ | ---------------- | ----------------------------------------------- |
| `000-*`                  | Sequential       | OS-specific initial setup                       |
| `001-*`                  | Sequential       | Homebrew installation                           |
| `002-*`                  | Sequential       | Brewfile package installation                   |
| `100-*` (Brew-dependent) | Sequential       | Configuration that depends on Homebrew packages |
| `100-*` (others)         | Parallel         | Independent tool configuration                  |

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

### 002-brewfile.sh

Installs the packages defined in `Brewfile` with `brew bundle`.

### 100-gh-extensions.sh

Installs GitHub CLI extensions and adds related tools.

- Install the `gh-q` (`HikaruEgashira/gh-q`) extension
- Install the `gh-infra` (`babarot/gh-infra`) extension (used for declarative repository settings with `.github/settings.yml`; see [gh-infra](./gh-infra.md) for details)
- Install `fd` (a fast file search tool) with Homebrew

### 100-ghostty.sh

Installs the Ghostty terminal emulator and configures terminfo (if not already installed).

- macOS: Install from Homebrew cask
- Linux: Install with the installation script
- On macOS, copy the terminfo from `/Applications/Ghostty.app` to `~/.terminfo/` (so `xterm-ghostty` is recognized)

### 100-lazyvim.sh

Sets up dependencies for LazyVim (the Neovim configuration framework).

### 100-mise.sh

Installs the tools managed by mise (`mise install`).

### 100-sheldon.sh

Installs sheldon and starship with Homebrew, then sets up plugins according to the lockfile.

- Install `sheldon` and `starship` with Homebrew
- Install plugins with `sheldon lock`

### 100-tmux.sh

Installs tmux Plugin Manager (tpm) and sets up plugins and dependency packages.

- Clone tpm into `~/.tmux/plugins/tpm/` (if not already installed)
- Install plugins with tpm
- Install common packages with Homebrew: `bash`, `bc`, `coreutils`, `gawk`, `gh`, `git`, `jq`
- Additional packages on macOS: `glab`, `gsed`, `nowplaying-cli`, `font-noto-sans-symbols-2`
- Additional package on Linux: `playerctl`

## Brew-dependent scripts

The following scripts depend on Homebrew packages, so they are run sequentially instead of in parallel:

- `100-ghostty.sh`
- `100-lazyvim.sh`
- `100-sheldon.sh`

## Adding scripts

When adding a new script:

1. Create `100-<name>.sh` in `scripts/`
2. If it depends on Homebrew, add it to `is_brew_dependent_100_script()` in `install.sh`

```bash
#!/bin/bash
# scripts/100-new-tool.sh

# Tool setup process
```
