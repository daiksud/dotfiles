# Issue 22: ターミナルのログからURLを抽出してブラウザで開く機能の追加

## 日付

2026-04-16

## 背景・目的

tmux のスクロールバックバッファに表示されている URL を素早くブラウザで開きたい。
毎回マウスでコピーして貼り付ける手間を省くため、fzf で選択してワンキーで開けるようにする。

## 変更内容

- `dotfiles/.config/tmux/open-url.sh` を新規作成
  - 引数で受け取ったペイン ID の全スクロールバックを `tmux capture-pane -S -` で取得
  - `grep -oE` で `http://` / `https://` URL を抽出、重複除去して `sort -u`
  - `fzf` でインタラクティブに選択
  - macOS では `open`、Linux では `xdg-open` でブラウザを起動
- `dotfiles/.config/tmux/tmux.conf` にキーバインドを追加
  - `prefix + u` で `display-popup` を通じてスクリプトを実行

## 備考

- `display-popup` により tmux のポップアップウィンドウで fzf が表示される
- URL 末尾の `.` `,` `;` `:` `!` `?` はトリムして誤検知を防ぐ
- キーバインドは `<prefix> u`（prefix は `C-t`）
