# Issue 23: gh hosts.yml を削除して .gitignore に追加

## 日付

2026-04-16

## 背景・目的

`dotfiles/.config/gh/hosts.yml` には GitHub 認証情報（ユーザー名等）が含まれており、リポジトリに含めるべきでないため削除し、再度追跡されないよう `.gitignore` に追加する。

## 変更内容

- `dotfiles/.config/gh/hosts.yml`: git から削除（ファイル自体も削除）
- `.gitignore`: `dotfiles/.config/gh/hosts.yml` を追加

## 備考

`dotfiles/.config/gh/config.yml` は既に `.gitignore` に含まれていた。
