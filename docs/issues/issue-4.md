# Issue 4: SSH接続時のStarshipプロンプト改善

## 日付

2026-04-15

## 背景・目的

SSH で Codespace に接続した際、どの Codespace にいるか・SSH接続かどうかをプロンプトで視覚的に即座に把握できるようにしたい。

## 変更内容

- `dotfiles/.config/starship.toml`
  - ローカル時はリンゴアイコン（）、SSH接続時はイナズマアイコン（⚡）をプロンプト先頭に表示
  - SSH + Codespace 接続時はアイコンに続けて Codespace 名を表示（例: `⚡ cuddly-orbit`）
    - `CODESPACE_NAME` 環境変数の末尾ハッシュ（例: `-g44qr9j6wj6vf96qx`）は `sed 's/-[^-]*$//'` で除去
  - `custom.local` モジュール: SSH非接続時にリンゴアイコンを表示
  - `custom.ssh_info` モジュール: SSH接続時に `⚡`（+ Codespace名）を表示
  - format 内では `${custom.X}` 形式（波括弧あり）で参照（`$custom.X` だと全モジュール展開+リテラルテキストと解釈されるため）

## 備考

- `SSH_CONNECTION` は SSH セッションでのみシェルにセットされる環境変数
- `CODESPACE_NAME` は GitHub Codespaces が自動的にセットする環境変数
