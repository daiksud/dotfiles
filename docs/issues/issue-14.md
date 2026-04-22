# Issue 14: tmux テーマの表示問題を修正

## 日付

2026-04-15

## 背景・目的

`tokyo-night-tmux` プラグイン（storm テーマ）で発生していた 2 つの問題を修正。

1. **黄色い表示**: 未フォーカスウィンドウのタブが全体的に黄色く見える
2. **テーマが適用されない（緑になる）**: tmux 起動時に Tokyo Night が適用されず、デフォルトの緑ステータスバーのままになる

## 変更内容

### 1. 黄色い表示（upstream バグ）
- `~/.tmux/plugins/tokyo-night-tmux/tokyo-night.tmux`
  - `window-status-format` の `window_last_flag` 条件式を修正
  - **修正前**: `#[fg=${THEME[yellow]}]#{?window_last_flag,󰁯  , }` — false 時のスペースにも yellow が適用
  - **修正後**: `#{?window_last_flag,#[fg=${THEME[yellow]}]󰁯  ,  }` — yellow を true 時のみ適用

### 2. テーマが適用されない問題（根本原因）
- `dotfiles/.config/tmux/tmux.conf`
  - **根本原因**: TPM は `tmux.conf` が `~/.config/tmux/` にあると検出すると、`TMUX_PLUGIN_MANAGER_PATH` を自動的に `~/.config/tmux/plugins/` に設定する。しかし実際のプラグインは `~/.tmux/plugins/` にインストールされており、ディレクトリ不一致でプラグインが実行されなかった
  - **修正**: `set-environment -g TMUX_PLUGIN_MANAGER_PATH '~/.tmux/plugins/'` を明示的に設定
  - **補助修正**: TPM の `run` コマンドに `PATH="/opt/homebrew/bin:..."` をインライン設定し、macOS Apple Silicon で Homebrew の bash 5+ が使われるようにした（プラグインが `declare -A` を使用するため）

## 備考

- プラグイン側の修正（黄色の問題）は `tpm` でアップデートすると上書きされる可能性がある
- PATH / TMUX_PLUGIN_MANAGER_PATH の設定は `tmux.conf` 側の変更なので永続する
