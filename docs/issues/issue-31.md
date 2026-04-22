# Issue 31: Parallelize 100-series scripts safely

## 日付

2026-04-22

## 背景・目的

`scripts/100-*` のセットアップ時間を短縮したいが、Homebrew 依存処理まで無条件に並列化するとロック競合などで不安定化しやすい。安全性を保ちながら並列実行できる構成にする。

## 変更内容

- `install.sh`: 実行オーケストレーションを見直し
  - `000-*/001-*/002-*` は逐次実行
  - `100-*` は分類して実行
    - brew 依存 (`100-ghostty.sh`, `100-lazyvim.sh`, `100-sheldon.sh`) は逐次
    - 非 brew 依存 (`100-tmux.sh`, `100-gh-extensions.sh`, `100-mise.sh` など) は並列
  - 並列数は `DOTFILES_PARALLEL_JOBS`（デフォルト3）で制御
  - 失敗ポリシーは「最後まで実行して失敗を集約し、最後に非0終了」

## 備考

- 既存スクリプト本体は変更せず、`install.sh` 側の実行制御だけを変更している。
