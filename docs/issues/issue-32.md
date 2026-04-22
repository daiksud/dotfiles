# Issue 32: .config 配下の追跡対象を明示指定に限定

## 日付

2026-04-22

## 背景・目的

`.config` 配下で Git に含める対象を明示したものだけに限定し、明示していないファイルやディレクトリが誤って追跡されるのを防ぐため。

## 変更内容

- `dotfiles/.config/.gitignore` を更新し、デフォルトで全てを ignore する設定に変更
- 明示対象（`ghostty`, `mise`, `nvim`, `sheldon`, `starship.toml`, `tmux`）のみを unignore
- 明示したディレクトリ配下のファイルも追跡できるよう `!/xxx/**` を追加

## 備考

必要な対象を追加する場合は、同じ形式で `.gitignore` に `!/path/` と `!/path/**`（ファイルの場合は `!/file`）を追記する。
