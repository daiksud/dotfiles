# Issue 27: リポジトリ内の個人特定情報(PII)をテンプレート化

## 日付

2026-04-21

## 背景・目的

リポジトリ内に実名、メールアドレス、アカウント名、ローカルユーザーディレクトリなどの個人特定情報が含まれていたため、共有しやすい形に匿名化したい。
Gitログは今回の対象外とし、追跡中ファイルの内容のみを対象に除去する。

## 変更内容

- `dotfiles/.gitconfig`: `user.name` と `user.email` を `<YOUR_NAME>`, `<YOUR_EMAIL>` に置換
- `dotfiles/.config/gh/hosts.yml`: GitHub ユーザー識別子を `<YOUR_GITHUB_USERNAME>` に置換
- `docs/issues/issue-15.md`: `/Users/...` の実ユーザー名入りパス例を汎用プレースホルダへ置換
- `README.md`: 置換が必要なプレースホルダ一覧と、PII混入の簡易チェックコマンドを追記

## 備考

- サードパーティ同梱ディレクトリ（例: `dotfiles/.config/tmux/plugins/**`）は編集対象外
- Git履歴の書き換えは未実施（スコープ外）
