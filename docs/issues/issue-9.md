# Issue 9: brew パッケージリストを Brewfile に共通化

## 日付

2026-04-15

## 背景・目的

brew のパッケージリストが Dockerfile と各スクリプトに重複して存在し、パッケージの追加・削除時に複数箇所を手動で同期する必要があった。
`Brewfile` を Single Source of Truth として導入し、Dockerfile のリスト管理を一元化する。

## 変更内容

- `Brewfile`: 新規作成。全 brew formula を列挙。フォント cask は `OS.mac?` 条件付きで記述（Linux では自動スキップ）
- `scripts/002-brewfile.sh`: 新規作成。`brew bundle --no-lock` を実行して Brewfile のパッケージをインストール
- `.devcontainer/Dockerfile`:
  - `brew install` のハードコードリストを削除
  - `COPY Brewfile` + `brew bundle --no-lock --file=Brewfile` に置き換え
  - RUN ブロックを適切に分割（COPY は RUN の外）

## 備考

- `scripts/100-lazyvim.sh`, `scripts/100-sheldon.sh` は変更なし（自己完結性を維持）
- 既存スクリプトによる重複インストールは `brew install` のべき等性により問題なし
- `gcc` は Brewfile の先頭に配置（homebrew 依存の基礎パッケージ）
