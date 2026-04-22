# Issue 30: Replace ghq with gh-q

## 日付

2026-04-22

## 背景・目的

リポジトリ選択・移動の運用を `ghq` から `gh-q` に統一し、GitHub CLI 拡張として管理できるようにする。

## 変更内容

- `Brewfile`: `brew "ghq"` を削除
- `scripts/100-gh-extensions.sh`: `gh` 拡張をまとめて管理するスクリプトへ整理し、`HikaruEgashira/gh-q` のインストール処理を追加
- `dotfiles/.zsh/go-to-ghq-repository.zsh`: `ghq root/list` ベースの選択処理を `gh q -- pwd` ベースへ変更
- `dotfiles/.zsh/edit-ghq-repository.zsh`: `ghq` ベースの候補選択を廃止し、`gh q nvim` を実行する構成へ変更

## 備考

関数名・エイリアス（`go-to-ghq-repository`, `ggr`, `edit-ghq-repository`, `egr`）は既存利用との互換性のため維持した。
`gh q` は主に対話時に利用されるため、拡張インストールは `100-*` 系スクリプトと同じ段階で実行して問題ない。
