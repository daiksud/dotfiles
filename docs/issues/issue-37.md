# Issue 37: Markdown 保存時に Prettier のテーブル整形を適用しない設定

## 日付

2026-04-23

## 背景・目的

Neovim の保存時フォーマットで Prettier が Markdown テーブルを整列し、意図しない見た目変更が発生していた。  
Markdown では Prettier を使わず、テーブルの自動アラインを回避したい。

## 変更内容

- `dotfiles/.config/nvim/lua/plugins/conform.lua` を新規作成
  - `conform.nvim` の `formatters_by_ft` を上書き
  - `markdown` / `markdown.mdx` から `prettier` を除外し、`markdownlint-cli2` と `markdown-toc` のみを使用
  - `format_on_save` を追加し、保存時にフォーマットを自動実行するよう設定
- `dotfiles/.markdownlint-cli2.cjs` を新規作成
  - `customRules` に `markdownlint-rule-table-format/rule.js` を読み込む設定を追加
  - `~/.local/share/mise/installs/npm-markdownlint-rule-table-format/latest/.../rule.js` を優先参照し、見つからない場合は `require.resolve` / `npm root -g` でフォールバックする解決ロジックを追加
  - `MD060.style = "compact"` および `table-format.style = "compact"` を設定
  - `markdownlint-cli2 --fix` 時にテーブルを compact 形式へ自動整形できるようにした
- `.markdownlint-cli2.cjs`（リポジトリルート）を新規作成
  - `module.exports = require("./dotfiles/.markdownlint-cli2.cjs")` の委譲設定を追加
  - `markdownlint-cli2 --fix README.md` のようにリポジトリルートで実行した場合でも同設定が確実に読まれるようにした
- `dotfiles/.config/mise/config.toml`
  - `npm:markdownlint-cli2` と `npm:markdownlint-rule-table-format` を追加し、ツールとカスタムルールをインストール対象にした

## 備考

Prettier には Markdown テーブルのアラインのみを無効化する公式オプションがないため、Markdown 向けでは Prettier を外し、`markdownlint-cli2` + `markdownlint-rule-table-format` で compact 整形を行う方針とした。
