# Issue 21: Fix nowplaying-cli failing in Codespace prebuild

## 日付

2026-04-16

## 背景・目的

Codespace のプリビルド（Linux 環境）で `brew bundle` が失敗していた。
`nowplaying-cli` は macOS 専用パッケージであり、Linux 上では
「`nowplaying-cli: macOS is required for this software.`」というエラーで
インストールに失敗するため、ビルドが中断されていた。

## 変更内容

- `Brewfile`: `brew "nowplaying-cli"` に `if OS.mac?` 条件を追加し、Linux 環境でスキップされるようにした

## 備考

`cask` エントリのフォント類はすでに `if OS.mac?` 条件が付いていた。
`nowplaying-cli` は tokyo-night-tmux の依存パッケージとして追加されているが、
Linux（Codespace）では tmux テーマの nowplaying 機能は使用できない。
