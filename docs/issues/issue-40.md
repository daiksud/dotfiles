# Issue 40: ghq リポジトリ選択時に github.com プレフィックスを除去する

## 日付

2026-05-25

## 背景・目的

`go-to-ghq-repository` 関数で fzf を使ってリポジトリを選択する際、`$HOME/ghq/github.com/` というパスプレフィックスがリスト表示されており、絞り込みの邪魔になっていた。`owner/repo` 形式のみで絞り込めるよう改善する。

## 変更内容

- `dotfiles/.zsh/go-to-ghq-repository.zsh`: `gh q list` の出力を `sed` で `$HOME/ghq/github.com/` プレフィックスを除去して fzf に渡す。選択後はプレフィックスを補完して `cd` する。`github.com` 以外のホスト（絶対パスのまま）も引き続き動作する。

## 備考

- `$HOME/ghq/github.com/` 配下のリポジトリは `owner/repo` 形式で表示される
- それ以外のホスト（`gitlab.com` など）は絶対パスのまま表示・移動できる
