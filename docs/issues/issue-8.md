# Issue 8: node と pnpm を mise で管理

## 日付

2026-04-15

## 背景・目的

`node` と `pnpm` を brew ではなく mise（ランタイムバージョンマネージャー）で管理することで、
バージョン切り替えを容易にし、ツール管理を一元化する。
また、prebuilt 時にリポジトリの mise 設定ファイルをそのまま利用できるよう構成する。

## 変更内容

- `dotfiles/.config/mise/config.toml`: `pnpm = "latest"` を追加
- `dotfiles/.zshrc`: `eval "$(mise activate zsh)"` を追加
- `scripts/100-lazyvim.sh`: `node` と `pnpm` を削除し、`mise` を追加
- `scripts/100-mise.sh`: 新規作成。`mise install` を実行してツールをインストール
- `.devcontainer/devcontainer.json`: `build.context` を `".."` に設定（リポジトリルートをビルドコンテキストにする）
- `.devcontainer/Dockerfile`:
  - `ENV MISE_DATA_DIR=/home/linuxbrew/mise` を追加（codespace ユーザー (UID 1001) がアクセスできるパス）
  - brew から `node` と `pnpm` を削除し、`mise` を追加
  - `COPY dotfiles/.config/mise/config.toml` でリポジトリの設定をそのまま利用
  - `mise install` で全ツールを prebuilt イメージに事前インストール
  - `chown` を `/home/linuxbrew/` 全体に拡張

## 備考

- `build.context: ".."` により、Dockerfile はリポジトリルートを基準にファイルを参照できる
- インライン定義の二重管理を解消し、`mise/config.toml` が唯一の真実のソースになる
