# Neovim

This is the configuration reference for Neovim (LazyVim).

## File

`dotfiles/nvim/` → `~/.config/nvim/`

## Structure

Minimal customizations are applied on top of LazyVim.

```
nvim/
├── init.lua              # Entry point (requires config.lazy)
├── lua/
│   ├── config/
│   │   ├── lazy.lua      # lazy.nvim bootstrap and configuration
│   │   ├── options.lua   # Additional options (currently empty)
│   │   ├── keymaps.lua   # Custom keymaps
│   │   └── autocmds.lua  # Additional autocmds (currently empty)
│   └── plugins/
│       ├── example.lua   # LazyVim sample (disabled)
│       └── tokyonight.lua # Color scheme settings
├── lazyvim.json          # LazyVim extras settings
└── stylua.toml           # Lua formatter settings
```

## LazyVim Extras

Extras enabled in `lazyvim.json`:

| Extra             | Description                 |
| ----------------- | --------------------------- |
| `ai.copilot`      | GitHub Copilot completion   |
| `editor.fzf`      | fzf file search             |
| `lang.json`       | JSON LSP and highlighting   |
| `lang.toml`       | TOML LSP and highlighting   |
| `lang.typescript` | TypeScript / JavaScript LSP |
| `lang.vue`        | Vue.js LSP                  |
| `linting.eslint`  | ESLint integration          |

## Custom keymaps

Adds Emacs-style cursor movement in insert mode:

| Key   | Action     |
| ----- | ---------- |
| `C-a` | Line start |
| `C-e` | Line end   |
| `C-b` | Left       |
| `C-f` | Right      |
| `C-n` | Down       |
| `C-p` | Up         |
| `C-d` | Delete     |
| `C-v` | Page Down  |
| `M-v` | Page Up    |

## Color scheme

Uses Tokyo Night Storm in transparent mode:

```lua
{
  "folke/tokyonight.nvim",
  opts = {
    style = "storm",
    transparent = true,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
  },
}
```

## lazy.nvim settings

| Setting               | Value                       | Description                                  |
| --------------------- | --------------------------- | -------------------------------------------- |
| `defaults.lazy`       | `false`                     | Load custom plugins at startup               |
| `defaults.version`    | `false`                     | Always use the latest git commit             |
| `checker.enabled`     | `true`                      | Periodically check for plugin updates        |
| `checker.notify`      | `false`                     | Do not show update notifications             |
| `install.colorscheme` | `["tokyonight", "habamax"]` | Fallback themes for the initial installation |

### Disabled rtp plugins

The following are disabled for performance optimization:

- `gzip`
- `tarPlugin`
- `tohtml`
- `tutor`
- `zipPlugin`
