# Issue 35: tmux + Ghostty 環境で Markdown を開くと文字が勝手に入力される問題の回避

## 日付

2026-04-23

## 背景・目的

`nvim README.md` のように Markdown ファイルを開いた直後、`ghostty 1.3.1` 由来の文字列がキー入力として解釈され、`ostty 1.3.1` のようなテキストがバッファに挿入される現象が発生していた。  
Markdown 表示時に有効化される画像関連処理が、tmux + Ghostty 環境で端末応答を誤って入力として扱うケースを回避する。

## 変更内容

- `dotfiles/.config/nvim/lua/plugins/snacks.lua`
  - 当初 `image.enabled` を `vim.env.TMUX == nil` にして tmux 内画像機能を全無効化したが、その後 `image.enabled = true` に戻した
  - 再発対応として `image.doc.enabled = vim.env.TMUX == nil` を追加
  - tmux 内では Markdown/HTML などドキュメント向けインライン画像描画のみ無効化し、画像ファイル表示機能は維持
- `dotfiles/.tmux.conf`
  - `set -g allow-passthrough on` を追加後、再発確認により `set -g allow-passthrough all` へ変更
  - tmux 3.6a 環境で端末制御シーケンスの透過条件を強め、tmux 内でも画像系機能との両立を狙って調整

## 備考

tmux 外（Ghostty 直下）では従来どおり `snacks.image` を有効にするため、通常環境での画像機能は維持される。
