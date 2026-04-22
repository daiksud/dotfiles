# Issue 28: install.sh で .gitconfig をコピー／同期するよう変更

## 日付

2026-04-21

## 背景・目的

`install.sh` の既存実装では `dotfiles/.gitconfig` を他ドットファイルと同様にシンボリックリンクしており、既存の `~/.gitconfig` がある環境でも置き換わる挙動だった。
`.gitconfig` だけはコピー運用にし、既存設定がある場合は `user.name` / `user.email` を除く差分をリポジトリ側へ反映できるようにする必要があった。

## 変更内容

- `install.sh`
  - 汎用シンボリックリンク処理から `.gitconfig` を除外
  - `~/.gitconfig` が存在しない場合のみ `dotfiles/.gitconfig` を `~/.gitconfig` へコピー
  - `~/.gitconfig` が存在する場合、`user.name` / `user.email` を除いたキーを比較し、差分があれば `~/.gitconfig` の内容を `dotfiles/.gitconfig` に同期
  - 同期時は全セクション・全キー（除外キーを除く）を対象にし、値差分とキー削除の双方を反映

## 備考

- `user.name` / `user.email` は個人情報保護のため同期対象外
- `.gitconfig` 以外のドットファイルは従来どおりシンボリックリンク運用
