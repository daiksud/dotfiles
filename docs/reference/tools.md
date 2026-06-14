# Tool list

This is the list of tools managed in the Brewfile and their purposes.

## CLI tools

| Package    | Purpose                                       |
| ---------- | --------------------------------------------- |
| `gcc`      | Homebrew build dependency                     |
| `bun`      | JavaScript runtime / package manager          |
| `fish`     | Fish shell (for subshell use)                 |
| `fzf`      | Fuzzy finder (file selection, history search) |
| `gh`       | GitHub CLI                                    |
| `git`      | Version control                               |
| `jq`       | JSON processor                                |
| `lazygit`  | TUI client for Git                            |
| `lua`      | Lua runtime (for Neovim plugins)              |
| `luarocks` | Lua package manager                           |
| `mise`     | Development tool version management           |
| `neovim`   | Text editor                                   |
| `node`     | Node.js runtime                               |
| `ripgrep`  | Fast text search                              |
| `rtk`      | CLI proxy for reducing LLM token usage        |
| `sheldon`  | Zsh plugin manager                            |
| `starship` | Cross-shell prompt                            |
| `tmux`     | Terminal multiplexer                          |
| `wget`     | HTTP downloader                               |

## GUI applications (cask)

| Package                | Purpose                       |
| ---------------------- | ----------------------------- |
| `copilot-cli`          | GitHub Copilot CLI            |
| `font-moralerspace-hw` | Programming font (macOS only) |

## Adding tools

Add an entry to `Brewfile`, then rerun `install.sh` or run `brew bundle` directly.

```bash
echo 'brew "new-tool"' >> Brewfile
brew bundle --file=Brewfile
```
