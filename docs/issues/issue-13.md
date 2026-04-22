# Issue 13: tmux Tokyo Night Storm テーマが適用されない問題の修正

## 日付

2026-04-15

## 背景・目的

`install.sh` を実行すると以下のエラーが発生し、TPM プラグイン（`tokyo-night-tmux`）のインストールが失敗していた。

```
unknown variable: TMUX_PLUGIN_MANAGER_PATH
FATAL: Tmux Plugin Manager not configured in tmux.conf
Aborting.
```

TPM の `install_plugins` スクリプトは `tmux show-environment -g TMUX_PLUGIN_MANAGER_PATH` でプラグインパスを取得するが、`scripts/100-tmux.sh` がこの環境変数をセットせずに呼び出していたため失敗していた。結果として `tokyo-night-tmux` プラグインが未インストールとなり、テーマが適用されなかった。

## 変更内容

- `scripts/100-tmux.sh`: `install_plugins` を呼ぶ前に `tmux start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH` を実行して環境変数をセットするよう修正
- `Brewfile`: `tokyo-night-tmux` の macOS 向け依存パッケージを追加
  - `bash`, `bc`, `coreutils`, `gawk`, `gsed`, `jq`, `nowplaying-cli`（brew）
  - `font-noto-sans-symbols-2`（cask）

## 備考

- `font-noto-sans-symbols-2` はセグメント数字（`digital` スタイル）の表示に必要
- `nowplaying-cli` は Now Playing ウィジェット用（macOS）
- `bash` は macOS デフォルトの bash 3.2 では動作しないため新しいバージョンが必要
