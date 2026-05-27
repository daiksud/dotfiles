# Issue 1: サイトタイトルを daiksud/dotfiles に変更

## 日付

2026-05-27

## 背景・目的

GitHub Pages のサイトタイトルが `dotfiles` のみだと、他のユーザーの dotfiles リポジトリと区別がつかない。`daiksud/dotfiles` とすることでリポジトリを一意に識別できるようにする。

## 変更内容

- `.docusaurus/docusaurus.config.ts` の `title`（サイト全体）を `daiksud/dotfiles` に変更
- 同ファイルの `navbar.title` も `daiksud/dotfiles` に変更

## 備考

なし
