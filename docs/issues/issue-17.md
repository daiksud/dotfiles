# Issue 17: tmux で Shift+Enter が効かない問題を修正

## 日付

2026-04-15

## 背景・目的

tmux 導入後、チャットアプリ等で `Shift+Enter` による改行が機能しなくなった。
tmux がデフォルトでは extended keys（修飾キー付き特殊キーのエスケープシーケンス）を
正しくターミナルに透過させないことが原因。

## 変更内容

- `dotfiles/.config/tmux/tmux.conf` に以下を追記した

  ```
  set -g extended-keys on
  set -as terminal-features 'xterm*:extkeys'
  set -as terminal-features 'tmux*:extkeys'
  ```

## 備考

- `extended-keys on` は tmux 3.3a 以降で利用可能
- Ghostty は xterm 互換のエスケープシーケンスを使用するため `xterm*` のパターンで対応できる
- 設定反映には tmux セッションの再起動、または `prefix + r` でのリロードが必要
