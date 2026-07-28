# Sheldon

This is the configuration reference for the Zsh plugin manager (sheldon).

## File

[`dotfiles/sheldon/plugins.toml`](https://github.com/daiksud/dotfiles/blob/main/dotfiles/sheldon/plugins.toml)
→ `~/.config/sheldon/plugins.toml`

## Top-level settings

The tracked configuration targets Zsh, so Sheldon generates initialization
content using Zsh syntax.

## Template

The configuration defines an `fpath` template that prepends a plugin directory
to the current function search path. Plugins assigned to this template
contribute completion definitions without having their files sourced. The
`zsh-completions` entry uses this behavior.

## Plugin list

| Plugin name                    | Repository                                   | Description                                       |
| ------------------------------ | -------------------------------------------- | ------------------------------------------------- |
| `fzf-tab`                      | `Aloxaf/fzf-tab`                             | Replace standard zsh completion with fzf          |
| `ohmyzsh-lib-git`              | `ohmyzsh/ohmyzsh` (lib/git.zsh)              | Utility functions required by the git plugin      |
| `ohmyzsh-git`                  | `ohmyzsh/ohmyzsh` (plugins/git)              | Git alias set (`gst`, `gco`, `gcm`, `gp`, etc.)   |
| `zsh-completions`              | `zsh-users/zsh-completions`                  | Additional completion definitions (`fpath` only)  |
| `zsh-autosuggestions`          | `zsh-users/zsh-autosuggestions`              | Fish-style inline suggestions                     |
| `zsh-autopair`                 | `hlissner/zsh-autopair`                      | Automatic pairing of brackets and quotes          |
| `fast-syntax-highlighting`     | `zdharma-continuum/fast-syntax-highlighting` | Command syntax highlighting                       |
| `zsh-history-substring-search` | `zsh-users/zsh-history-substring-search`     | Substring history search for the text being typed |

## Load-order constraints

1. **Run `compinit` first** — In `.zshrc`, call `compinit` before `sheldon source` so plugins that use `compdef` work correctly
2. **Load `history-substring-search` after syntax highlighting** — sheldon sources plugins in TOML definition order, so write `fast-syntax-highlighting` first

## Adding plugins

```toml
[plugins.new-plugin]
github = "author/new-plugin"
```

After adding one:

```bash
sheldon lock --update
```
