# Tool list

This is the list of tools managed in the Brewfile and their purposes.

Node.js and Bun are managed by [Vite+](./vite-plus.md), not by `Brewfile`.

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

## GUI applications (cask)

| Package | Purpose |
| ---------------------- | ----------------------------- |
| `font-moralerspace-hw` | Programming font (macOS only) |

## Adding tools

Add an entry to `Brewfile`, then rerun `install.sh` or run `brew bundle` directly.

```bash
echo 'brew "new-tool"' >> Brewfile
brew bundle --file=Brewfile
```
