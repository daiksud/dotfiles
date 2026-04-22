# Issue 12: tmux および関連ツールを Tokyo Night Storm に統一

## 日付

2026-04-15

## 背景・目的

tmux が Catppuccin Mocha テーマを使用しており、他ツールとカラーテーマが不統一だった。
Ghostty が Tokyo Night Moon、Neovim が Tokyo Night Storm（暗黙）を使用していたため、
すべてのツールを Tokyo Night Storm に揃えることで開発環境のカラーテーマを統一する。

## 変更内容

- `dotfiles/.config/tmux/tmux.conf`: `catppuccin/tmux` プラグインを削除し `janoamaral/tokyo-night-tmux` に置き換え。フレーバーを `storm` に設定
- `dotfiles/.config/ghostty/config`: `theme = TokyoNight Moon` → `theme = TokyoNight Storm`
- `dotfiles/.config/nvim/lua/plugins/tokyonight.lua`: `style = "storm"` を明示的に追加

## 備考

- tmux プラグインの実際のインストールは TPM で手動実行が必要: `prefix + I`
- Ghostty のテーマ名はスペース区切り（`TokyoNight Storm`）
