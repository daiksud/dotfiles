# Issue 19: tmux 内で Shift+Enter が改行されず送信される問題の修正

## 日付

2026-04-15

## 背景・目的

tmux 内で GitHub Copilot CLI のチャットを使用中、Shift+Enter を押すと改行ではなくメッセージ送信が行われてしまう問題を修正する。tmux 導入前（Ghostty から直接起動時）は正常に改行できていた。

## 原因

- **tmux なし**: Ghostty が kitty keyboard protocol 形式 (`\e[13;2u`) で Shift+Enter を Copilot CLI に送信 → アプリが認識して改行 ✅
- **tmux あり**: `extended-keys always` 設定でも tmux は独自形式 (`\e[13;2~`) に変換して転送するため、Copilot CLI が認識できず submit として処理されてしまう ❌

## 変更内容

- `dotfiles/.config/tmux/tmux.conf`
  - `set -g extended-keys on` → `set -g extended-keys always` に変更（tmux のキー転送を有効化）
  - `bind -n S-Enter send-keys "\e[13;2u"` を追加
    - tmux が Shift+Enter を受け取った際に、アプリが期待する kitty keyboard protocol 形式 (`\e[13;2u`) に変換して転送する

## 備考

kitty keyboard protocol の Shift+Enter エンコーディング: `\e[13;2u`（modifier 2 = Shift）。Ghostty, Neovim, GitHub Copilot CLI など kitty protocol 対応アプリはこの形式を期待する。
