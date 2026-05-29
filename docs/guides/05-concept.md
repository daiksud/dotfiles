# コンセプト

この dotfiles リポジトリの設計思想と方針を説明します。

## ワンコマンドで完結する再現性

新しいマシンでも `bash install.sh` の 1 コマンドだけで、シェル・エディタ・ターミナル・CLI ツールがすべて揃った状態を再現できることを最優先にしている。

手動の設定手順やインストール後の追加作業を極力排除し、スクリプトに落とし込む。

## 宣言的な設定管理

- **シンボリックリンク** — `install_map.json` で source → target を宣言
- **パッケージ** — `Brewfile` で必要なツールを宣言
- **プラグイン** — `plugins.toml`（sheldon）で Zsh プラグインを宣言
- **ランタイム** — `config.toml`（mise）で言語バージョンを宣言

「何を入れるか」はすべて設定ファイルに書かれており、スクリプトは「設定ファイルを適用する」だけ。

## テーマは Tokyo Night Storm で統一

すべてのツールのカラースキームを **Tokyo Night Storm** に統一している。

| ツール   | 設定                                                   |
| -------- | ------------------------------------------------------ |
| Ghostty  | `theme = TokyoNight Storm`                             |
| Neovim   | `tokyonight.nvim` (style = `"storm"`, transparent)     |
| tmux     | `tokyo-night-tmux` (theme = `storm`)                   |
| Starship | Tokyo Night Storm の配色に合わせたカスタムフォーマット |

ターミナル → tmux → エディタ間で色の断絶がなく、視覚的に一貫した環境になる。

## マルチアカウント対応

GitHub アカウントを複数使い分ける前提で設計している。

- `GH_CONFIG_DIR` をリポジトリ単位で分離
- `user.name` / `user.email` / `user.signingkey` はグローバルに設定しない
- `cd` するだけで適切なアカウントに自動切り替え

## 最小限の外部依存

- シェルフレームワーク（Oh-My-Zsh 等）に依存しない
- 各ツールの責務を分離し、単一障害点を作らない
- macOS と Ubuntu (Codespaces) の両方で動作する

## 冪等性

`install.sh` は何度実行しても同じ結果に収束する。途中で失敗しても再実行すれば正しい状態になる。
