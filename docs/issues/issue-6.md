# Issue 6: gh config.yml を削除して .gitignore に追加

## 日付

2026-04-15

## 背景・目的

`dotfiles/.config/gh/config.yml` はユーザー固有の認証情報や設定を含む可能性があるため、リポジトリで管理すべきでない。
ファイルを削除し、今後も誤ってコミットされないよう `.gitignore` に追加する。

## 変更内容

- `dotfiles/.config/gh/config.yml`: リポジトリから削除
- `.gitignore`: 新規作成し `dotfiles/.config/gh/config.yml` を追加

## 備考

なし
