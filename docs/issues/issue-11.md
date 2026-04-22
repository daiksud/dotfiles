# Issue 11: tmux 導入

## 日付

2026-04-15

## 背景・目的

ターミナルマルチプレクサとして tmux を導入し、セッション・ウィンドウ・ペイン管理を可能にする。
TPM (Tmux Plugin Manager) でプラグインを管理し、Catppuccin テーマで統一感のある外観にする。

## 変更内容

- `Brewfile`: `brew "tmux"` を追加（Codespaces prebuilt でも自動インストール）
- `dotfiles/.config/tmux/tmux.conf`: 新規作成
  - prefix: `C-t`
  - vi コピーモード (`v` で選択開始、`y` でコピー)
  - マウス操作有効
  - ペイン分割: `|` (水平) / `-` (垂直)、vim ライクなペイン移動
  - TPM プラグイン: `tmux-sensible`、`catppuccin/tmux` (mocha フレーバー)
- `scripts/100-tmux.sh`: 新規作成（TPM のクローン＋`install_plugins` 実行）
- `dotfiles/.zshrc`: tmux 自動起動を追加
  - `exec tmux new-session -A -s main` で既存セッションに attach、なければ新規作成
  - `exec` によりシェルプロセスが tmux に置き換わるため、tmux 終了時にターミナルが閉じる（zsh に戻らない）
  - `tmux` コマンドが存在する場合のみ実行（`command -v tmux` チェック）

## 備考

- `dotfiles/.config/tmux/` は `install.sh` による `~/.config` シンボリックリンク経由で `~/.config/tmux/tmux.conf` として参照される
- TPM はデフォルトの `~/.tmux/plugins/tpm` にインストールされる
- `tmux-sensible` は基本的な設定を自動適用するプラグイン
