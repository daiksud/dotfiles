# Issue 34: Improve zsh directory navigation workflow

## 日付

2026-04-22

## 背景・目的

`go-to-ghq-repository` の遷移体験を改善し、普段のシェル操作でもディレクトリ移動をより効率化する。

## 変更内容

- `dotfiles/.zsh/go-to-ghq-repository.zsh`: 引数または `LBUFFER` を初期クエリとして取り込み、`gh q list | fzf` で候補選択して移動するように変更。
- `dotfiles/.zshrc`: `auto_cd` / `auto_pushd` / `pushd_ignore_dups` を追加し、ディレクトリ移動履歴の操作性を改善。

## 備考

`go-to-ghq-repository` は引数なし実行時に現在の入力バッファを初期検索語として利用できる。
