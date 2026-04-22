# Issue 5: Fix missing brew PATH in sheldon and ghostty scripts

## 日付

2026-04-15

## 背景・目的

`100-sheldon.sh` を実行した際に `brew: command not found` エラーが発生した。
`brew` は `/home/linuxbrew/.linuxbrew/bin/brew` にインストールされているが、スクリプト実行時に PATH が設定されていないため、`brew` コマンドが見つからない状態になっていた。

## 変更内容

- `scripts/100-sheldon.sh`: `brew` 使用前に `brew shellenv` による PATH 設定を追加
- `scripts/100-ghostty.sh`: macOS での `brew` 使用前に `brew shellenv` による PATH 設定を追加

## 備考

`scripts/100-lazyvim.sh` は既に同様の対応がされていたため、変更不要。
