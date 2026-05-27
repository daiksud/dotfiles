# スクリプト一覧

`scripts/` 以下のセットアップスクリプトの役割と実行順序を説明します。

## 実行順序

スクリプトはファイル名の番号プリフィックスによってグループ化されます。

| グループ | 実行方法 | 説明 |
|---|---|---|
| `000-*` | 逐次 | OS 固有の初期設定 |
| `001-*` | 逐次 | Homebrew のインストール |
| `002-*` | 逐次 | Brewfile パッケージのインストール |
| `100-*`（Brew 依存） | 逐次 | Homebrew パッケージに依存する設定 |
| `100-*`（その他） | 並列 | 独立したツール設定 |

## スクリプト詳細

### 000-codespace.sh

Codespaces (Ubuntu) 固有の初期設定を行います。macOS では何もしません。

- タイムゾーンを `Asia/Tokyo` に設定
- デフォルトシェルを zsh に変更
- `build-essential`, `git` をインストール

### 001-homebrew.sh

Homebrew が未インストールの場合にインストールします。

- macOS: `/opt/homebrew/bin/brew`
- Linux: `/home/linuxbrew/.linuxbrew/bin/brew`

インストール後に `gcc` をアップグレードします。

### 002-brewfile.sh

`Brewfile` に定義されたパッケージを `brew bundle` でインストールします。

### 100-gh-extensions.sh

GitHub CLI の拡張機能をインストールします。

### 100-ghostty.sh

Ghostty ターミナルエミュレータをインストールします（未インストールの場合）。

- macOS: Homebrew cask からインストール
- Linux: インストールスクリプトで導入

### 100-lazyvim.sh

LazyVim (Neovim 設定フレームワーク) の依存関係を設定します。

### 100-mise.sh

mise で管理するツール群をインストールします（`mise install`）。

### 100-sheldon.sh

sheldon プラグインマネージャでプラグインをロックファイルに従ってインストールします。

### 100-tmux.sh

tmux Plugin Manager (tpm) をインストールし、プラグインをセットアップします。

## Brew 依存スクリプト

以下のスクリプトは Homebrew パッケージに依存するため、並列実行されず逐次実行されます:

- `100-ghostty.sh`
- `100-lazyvim.sh`
- `100-sheldon.sh`

## スクリプトの追加

新しいスクリプトを追加する場合:

1. `scripts/` に `100-<name>.sh` を作成
2. Homebrew に依存する場合は `install.sh` の `is_brew_dependent_100_script()` に追加

```bash
#!/bin/bash
# scripts/100-new-tool.sh

# ツールのセットアップ処理
```
