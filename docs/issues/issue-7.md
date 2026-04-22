# Issue 7: Codespaces prebuilt に install.sh のパッケージを同期

## 日付

2026-04-15

## 背景・目的

`install.sh` が実行する `scripts/` 配下のスクリプトでインストールされる brew パッケージが、Codespaces prebuilt 用の `.devcontainer/Dockerfile` に反映されていなかった。
prebuilt イメージに予めパッケージを含めることで、Codespace 起動時のセットアップ時間を短縮する。

## 変更内容

- `.devcontainer/Dockerfile`: `brew install` に `sheldon` と `starship` を追加
  - `scripts/100-sheldon.sh` でインストールされるが Dockerfile に欠けていた
  - `font-moralerspace-*` は macOS cask のみ対応のため Linux (Dockerfile) ではスキップ

## 備考

- Dockerfile はすでに `100-lazyvim.sh` のパッケージの大半を含んでいたが、`100-sheldon.sh` 分が未反映だった
- `sheldon lock` はドットファイルが配置された後に実行される必要があるため、Dockerfile ではバイナリのインストールのみ行う
