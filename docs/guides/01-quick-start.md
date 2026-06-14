# Quick Start

This is the shortest procedure for reproducing the development environment on a new machine (or in Codespaces).

By the end of this guide, your shell configuration, editor (Neovim), terminal (Ghostty), and various CLI tools will all be set up.

## 1. Clone the repository

```bash
git clone https://github.com/daiksud/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

## 2. Run the installation script

```bash
bash install.sh
```

What this script does:

1. Creates symbolic links according to `install_map.json`
2. Installs Homebrew if it is not already installed
3. Installs the packages listed in `Brewfile`
4. Runs each setup script in `scripts/`

## 3. Restart the shell

```bash
exec zsh
```

If the Starship prompt appears, the setup was successful.

## Verification

```bash
# Check whether Neovim starts
nvim --version

# Check whether tool versions are managed by mise
mise list

# Check whether gh CLI is authenticated
gh auth status
```

## Next steps

- [Installation details](./02-installation.md) — Learn how `install.sh` works in detail
- [Adding and changing links](./03-managing-links.md) — Add a new configuration file to the managed set
- [Automatic Git ID switching](./04-git-identity.md) — Use multiple GitHub accounts
