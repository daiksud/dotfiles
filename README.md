# dotfiles

These dotfiles reproduce a unified development environment for macOS / Ubuntu (Codespaces).

## Setup

```bash
git clone https://github.com/daiksud/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash install.sh
```

## Included

| Category        | Contents                                                |
| --------------- | ------------------------------------------------------- |
| Shell           | Zsh + Starship prompt + sheldon plugins                 |
| Editor          | Neovim (LazyVim)                                        |
| Terminal        | Ghostty + tmux                                          |
| Tool management | Homebrew + mise                                         |
| Git             | Automatic multi-account switching (gh-config-dir) + SSH signing |
| CLI             | gh, fzf, ripgrep, lazygit, jq                           |

## How it works

`install_map.json` defines the symbolic link mapping table, and `install.sh` creates links based on it.

```json
{
  "links": {
    "zshrc": "~/.zshrc",
    "nvim": "~/.config/nvim",
    "starship.toml": "~/.config/starship.toml"
  }
}
```

For details, see the [documentation](./docs/README.mdx).

## Supported platforms

- macOS (Apple Silicon)
- Ubuntu (GitHub Codespaces)

## Documentation

- [Guides](./docs/guides/README.md) — from setup to everyday usage
- [Reference](./docs/reference/README.md) — details for configuration files and the tool list
- [Development](./docs/development/README.md) — repository structure, customization, and ADRs
