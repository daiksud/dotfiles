# Issue 10: LazyVim の warning を解消

## 日付

2026-04-15

## 背景・目的

`:checkhealth` 実行時に表示される warning を分析し、解消可能なものを対処した。

## 解消した warning

| プラグイン | 件数 | 内容 | 対処 |
|---|---|---|---|
| render-markdown | 3件 | latex treesitter パーサー未インストール | latex サポートを無効化 |
| snacks.image | 2件 | treesitter parser 不足 (css/scss/svelte/vue) | treesitter ensure_installed に追加 |
| fzf-lua | 2件 | viu/chafa 未インストール | Brewfile に追加 |

## 無視した warning（対処不要）

| プラグイン | 理由 |
|---|---|
| lazy/luarocks lua5.1 | lazy.nvim が「no plugins require luarocks, ignore」と明言 |
| conform Condition failed | プロジェクトに設定ファイル不在時の期待動作 |
| mason 言語 runtime | 使用しない言語（Go/Java/cargo 等）|
| snacks picker/statuscolumn disabled | fzf-lua 使用のため意図的 |
| fzf-lua ueberzugpp | viu/chafa で代替可能 |
| snacks dashboard argc | nvim 起動引数がある場合の既知動作 |

## 変更内容

- `dotfiles/.config/nvim/lua/plugins/render-markdown.lua`: 新規作成。`latex = { enabled = false }` を設定
- `dotfiles/.config/nvim/lua/plugins/treesitter.lua`: 新規作成。`css`, `scss`, `svelte`, `vue` を `ensure_installed` に追加
- `Brewfile`: `viu`（Rust 製・高速）と `chafa`（多モード対応）を追加。Ghostty の kitty protocol 対応済みなので両方とも高品質表示可能

## 備考

- `viu` と `chafa` はどちらも Ghostty の kitty graphics protocol に対応しており、fzf-lua が自動選択する
- `ueberzugpp` の warning は残るが、viu/chafa がある場合は実用上問題なし
