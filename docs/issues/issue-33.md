# Issue 33: tmux 設定を `~/.tmux` 系へ統一

## 日付

2026-04-22

## 背景・目的

`.config` 再作成を伴う再インストールで tmux テーマ適用が揺らぎやすかったため、
tmux の設定・補助スクリプト・プラグイン経路を `~/.tmux` 系に統一し、参照経路の分散をなくす。

## 変更内容

- `dotfiles/.tmux.conf` を新規作成し、tmux の設定エントリを `~/.tmux.conf` に統一
  - リロード先を `source-file ~/.tmux.conf` に変更
  - 補助スクリプト参照を `~/.tmux/*.sh` に変更
- `dotfiles/.tmux/` を新規作成し、補助スクリプトを移設
  - `start-logging.sh`
  - `collect-urls.sh`
  - `open-url.sh`
- 旧配置の `dotfiles/.config/tmux/*` を削除
- `.gitignore` の TPM プラグイン無視パスを `dotfiles/.tmux/plugins/` に変更
- TPM 実体は従来通り `~/.tmux/plugins` を使用（`scripts/100-tmux.sh` と `~/.tmux.conf` の参照を一致）

## 備考

- `~/.tmux.conf` を入口にすることで tmux 標準探索に沿った構成となり、
  `~/.config/tmux` の有無に影響されにくくなる。
