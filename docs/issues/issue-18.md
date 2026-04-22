# Issue 18: tmux 内で $TERM=xterm-ghostty を維持する

## 日付

2026-04-15

## 背景・目的

tmux 起動後も `$TERM` を `xterm-ghostty` に維持することで、tmux 内のプログラムが
Ghostty 固有のターミナル機能（キーボードプロトコル、Truecolor、underline-style 等）を
フル活用できるようにする。

## 変更内容

- `scripts/100-ghostty.sh`
  - Ghostty app bundle 内の terminfo を `~/.terminfo/` にコピーする処理を追加
  - これにより `xterm-ghostty` がシステム全体で認識されるようになる

- `dotfiles/.config/tmux/tmux.conf`
  - `default-terminal` を `"tmux-256color"` から `"xterm-ghostty"` に変更
  - `terminal-features` に `ghostty*:extkeys` を追加

## 備考

- ローカル専用環境での使用を前提とした変更（SSH 先での互換性は未考慮）
- terminfo は `/Applications/Ghostty.app/Contents/Resources/terminfo/` からコピー
- 設定反映には tmux セッションの再起動が必要
