# Neovim

Neovim（LazyVim）の設定リファレンスです。

## ファイル

`dotfiles/nvim/` → `~/.config/nvim/`

## 構成

LazyVim をベースに最小限のカスタマイズを行っている。

```
nvim/
├── init.lua              # エントリポイント（config.lazy を require）
├── lua/
│   ├── config/
│   │   ├── lazy.lua      # lazy.nvim ブートストラップと設定
│   │   ├── options.lua   # 追加オプション（現在は空）
│   │   ├── keymaps.lua   # カスタムキーマップ
│   │   └── autocmds.lua  # 追加 autocmd（現在は空）
│   └── plugins/
│       ├── example.lua   # LazyVim サンプル（無効化済み）
│       └── tokyonight.lua # カラースキーム設定
├── lazyvim.json          # LazyVim extras 設定
└── stylua.toml           # Lua フォーマッタ設定
```

## カスタムキーマップ

インサートモードで Emacs 風カーソル移動を追加:

| キー | 動作 |
|------|------|
| `C-a` | 行頭 |
| `C-e` | 行末 |
| `C-b` | 左 |
| `C-f` | 右 |
| `C-n` | 下 |
| `C-p` | 上 |
| `C-d` | Delete |
| `C-v` | Page Down |
| `M-v` | Page Up |

## カラースキーム

Tokyo Night Storm を透過モードで使用:

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

## lazy.nvim 設定

| 設定 | 値 | 説明 |
|------|-----|------|
| `defaults.lazy` | `false` | カスタムプラグインは起動時にロード |
| `defaults.version` | `false` | 常に最新の git commit を使用 |
| `checker.enabled` | `true` | プラグイン更新を定期チェック |
| `checker.notify` | `false` | 更新通知を表示しない |
| `install.colorscheme` | `["tokyonight", "habamax"]` | 初回インストール時のフォールバックテーマ |

### 無効化された rtp プラグイン

パフォーマンス最適化のため以下を無効化:

- `gzip`
- `tarPlugin`
- `tohtml`
- `tutor`
- `zipPlugin`
