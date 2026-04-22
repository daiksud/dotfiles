# Issue 26: ohmyzsh/lib/git.zsh を sheldon に追加

## 日付

2026-04-20

## 背景・目的

`ohmyzsh/plugins/git` はいくつかのユーティリティ関数を `lib/git.zsh` に依存している。
`lib/git.zsh` を明示的にロードすることで、git プラグインのエイリアスや関数が正しく動作するようにする。

## 変更内容

- `dotfiles/.config/sheldon/plugins.toml`: `ohmyzsh-lib-git` プラグインを追加（`ohmyzsh/ohmyzsh` の `lib/git.zsh` を `ohmyzsh-git` より先にロード）

## 備考

sheldon では同じ GitHub リポジトリを複数のプラグインとして登録できる。
`dir` と `use` を組み合わせることで特定ファイルのみをソース対象にできる。
