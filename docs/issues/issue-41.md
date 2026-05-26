# Issue 41: SSH 署名鍵のアカウント連動自動切り替え

## 日付

2026-05-26

## 背景・目的

GitHub アカウントを複数使い分ける環境で、`gh auth` のログインユーザーに応じてコミット署名鍵が自動的に切り替わらないため、異なるアカウントのリポジトリで Unverified コミットが発生していた。

既存の `sync_git_identity_from_gh` が `user.name`/`user.email` をリポジトリローカルに設定する仕組みを活用し、署名鍵も同様に自動設定する機能を追加する。

## 変更内容

- `dotfiles/.zsh/gh-config-dir.zsh` に `sync_signing_key_from_gh` 関数を追加
  - `gh api user` からログイン名を取得し、`~/.ssh/<login>.pub` を署名鍵パスとして解決
  - `git config --local` で `user.signingkey`, `gpg.format`, `commit.gpgsign` を設定
  - `~/.ssh/allowed_signers` を現在の email + 鍵で更新（ローカル署名検証用）
  - 鍵ファイルが存在しない場合は警告表示のみでスキップ
- `sync_git_identity_from_gh` の両方の終了パスから `sync_signing_key_from_gh` を呼び出すよう変更

## 備考

- 前提: アカウントごとに `~/.ssh/<login>` / `~/.ssh/<login>.pub` を事前に作成し、GitHub の Signing Keys に登録しておく必要がある。
- `allowed_signers` は単一ユーザーマシン前提で毎回上書きする設計。
