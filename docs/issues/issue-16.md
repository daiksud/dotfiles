# Issue 16: Ghostty タブ・スプリット関連キーバインドを無効化

## 日付

2026-04-15

## 背景・目的

Ghostty のデフォルトキーバインドに含まれるタブ・スプリット関連のショートカットを
意図せず発動させないよう、すべて `unbind` で無効化する。

## 変更内容

- `dotfiles/.config/ghostty/config` に以下の `keybind = <key>=unbind` を追記した

  **タブ関連**
  - `super+t` (新規タブ)
  - `super+shift+left_bracket` / `super+shift+right_bracket` (前後のタブ)
  - `super+one`〜`super+nine` (タブ番号直接移動)

  **スプリット関連**
  - `super+d` / `super+shift+d` (垂直・水平分割)
  - `super+opt+up/down/left/right` (分割ペイン間の移動)
  - `super+ctrl+up/down/left/right` (分割ペインのリサイズ)
  - `super+shift+enter` (ペインズーム切り替え)

## 備考

- `unbind` を指定すると macOS のシステムショートカットにも渡されなくなる
- `super+w` (close_surface) はタブ・スプリット両方に影響するが、今回は対象外とした
