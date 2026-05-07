# Issue 39: dotfiles の不要設定を削除・整理

## 日付

2026-05-07

## 背景・目的

dotfiles が肥大化し、実際には使っていないツールや設定が混在していたため整理する。

## 変更内容

- **Brewfile**: 使わないパッケージを削除（ast-grep, awscli, chafa, fd, gs, imagemagick, viu）。tokyo-night-tmux の依存は `scripts/100-tmux.sh` に移動
- **dotfiles/.config/mise/config.toml**: 不要な node/python/npm ツール群を削除し、bun のみに整理
- **dotfiles/.config/starship.toml**: SSH/ローカル判定の custom モジュールを削除しシンプル化。bun セクションを追加
- **dotfiles/.markdownlint-cli2.cjs**: 削除（mise の markdownlint-cli2 も削除したため不要）
- **.markdownlint-cli2.cjs**（リポジトリルート）: 削除
- **.gitignore**: 内容をクリア（不要なエントリを削除）
- **dotfiles/.tmux.conf**: 未使用のターミナル設定、tokyo-night-tmux の詳細オプション、URL 抽出機能（pane logging + popup）を削除
- **dotfiles/.tmux/collect-urls.sh, open-url.sh, start-logging.sh**: 削除（URL 抽出機能の廃止）
- **scripts/100-lazyvim.sh**: 使わないパッケージを削除（ast-grep, fd, gs, imagemagick, mermaid-cli）
- **scripts/100-tmux.sh**: tokyo-night-tmux の依存パッケージインストールを追加（Brewfile から移動）

## 備考

- tokyo-night-tmux の依存パッケージはセットアップスクリプト側で管理する方針に変更
- nvim の lazy-lock.json / lazyvim.json の更新も含まれる
