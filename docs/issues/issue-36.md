# Issue 36: Neovim の Markdown テーブル折り返しを無効化

## 日付

2026-04-23

## 背景・目的

Neovim で Markdown を表示中、テーブル行がウィンドウ幅で折り返されて可読性が低下していた。  
Markdown バッファでは行を折り返さず、横スクロールで確認できる表示に固定する。

## 変更内容

- `dotfiles/.config/nvim/lua/config/autocmds.lua`
  - `FileType=markdown` の autocmd を追加
  - `wrap = false`, `linebreak = false` を設定し、折り返しを無効化
  - `sidescroll = 1`, `sidescrolloff = 5` を設定し、横方向の閲覧性を改善

## 備考

Markdown 以外のファイルタイプには影響しない。
