# Issue 14: tmux テーマの表示問題を修正

## 日付

2026-04-15

## 背景・目的

`tokyo-night-tmux` プラグイン（storm テーマ）で発生していた 2 つの問題を修正。

1. **黄色い表示**: 未フォーカスウィンドウのタブが全体的に黄色く見える
2. **テーマが適用されない（緑になる）**: tmux 起動時に Tokyo Night が適用されず、デフォルトの緑ステータスバーのままになる

## 変更内容

### 1. 黄色い表示（依存パッケージ不足）
- **根本原因**: [tokyo-night-tmux の Quick Start](https://github.com/janoamaral/tokyo-night-tmux#quick-start) に記載されている必要パッケージがインストールされていなかった
- **修正**: macOS で必要な依存パッケージをインストール:
  ```sh
  brew install bash bc coreutils gawk gh glab gsed jq nowplaying-cli
  ```
- 当初 `window_last_flag` の条件式が原因と思われたが、関係なかった

### 2. テーマが適用されない問題（根本原因）
- `dotfiles/.config/tmux/tmux.conf`
  - **根本原因**: TPM は `tmux.conf` が `~/.config/tmux/` にあると検出すると、`TMUX_PLUGIN_MANAGER_PATH` を自動的に `~/.config/tmux/plugins/` に設定する。しかし実際のプラグインは `~/.tmux/plugins/` にインストールされており、ディレクトリ不一致でプラグインが実行されなかった
  - **修正**: `set-environment -g TMUX_PLUGIN_MANAGER_PATH '~/.tmux/plugins/'` を明示的に設定
  - **補助修正**: TPM の `run` コマンドに `PATH="/opt/homebrew/bin:..."` をインライン設定し、macOS Apple Silicon で Homebrew の bash 5+ が使われるようにした（プラグインが `declare -A` を使用するため）

## 備考

- `window_last_flag` の条件式修正は不要だった（プラグインを `tpm` で再インストールしても問題ない）
- PATH / TMUX_PLUGIN_MANAGER_PATH の設定は `tmux.conf` 側の変更なので永続する
