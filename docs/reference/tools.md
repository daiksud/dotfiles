# Tool list

This is the list of CLI formulas managed in the Brewfile and their purposes.
Homebrew Cask is not used.

Repository-local Node.js and Bun are managed by [mise](./mise.md), not by `Brewfile`.

## CLI tools

| Package | Purpose |
| ---------- | --------------------------------------------- |
| `gcc` | Homebrew build dependency |
| `apm` | Global AI agent package and skill manager |
| `fish` | Fish shell (for subshell use) |
| `fzf` | Fuzzy finder (file selection, history search) |
| `gh` | GitHub CLI |
| `git` | Version control |
| `herdr` | Terminal multiplexer |
| `jq` | JSON processor |
| `lazygit` | TUI client for Git |
| `lua` | Lua runtime (for Neovim plugins) |
| `luarocks` | Lua package manager |
| `mise` | Development tool version management |
| `neovim` | Text editor |
| `ripgrep` | Fast text search |
| `sheldon` | Zsh plugin manager |
| `starship` | Cross-shell prompt |
| `wget` | HTTP downloader |

## Manually installed macOS applications and fonts

- [Ghostty](https://ghostty.org/download) — Terminal emulator
- [Moralerspace releases](https://github.com/yuru7/moralerspace/releases) — Install `Moralerspace Neon HW` from the HW archive

See the [installation guide](../guides/02-installation.md#macos-applications-and-fonts) for setup.

## Adding tools

Add a CLI formula entry to `Brewfile`, then rerun `install.sh` or run `brew bundle` directly.

```bash
echo 'brew "new-tool"' >> Brewfile
brew bundle --file=Brewfile
```
