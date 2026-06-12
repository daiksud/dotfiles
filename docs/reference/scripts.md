# スクリプト一覧

`scripts/` 以下のセットアップスクリプトの役割と実行順序を説明します。

## 実行順序

スクリプトはファイル名の番号プリフィックスによってグループ化されます。

| グループ             | 実行方法 | 説明                              |
| -------------------- | -------- | --------------------------------- |
| `000-*`              | 逐次     | OS 固有の初期設定                 |
| `001-*`              | 逐次     | Homebrew のインストール           |
| `002-*`              | 逐次     | Brewfile パッケージのインストール |
| `100-*`（Brew 依存） | 逐次     | Homebrew パッケージに依存する設定 |
| `100-*`（その他）    | 並列     | 独立したツール設定                |

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

インストール後に `gcc` をインストールし、全パッケージを `brew upgrade` でアップグレードします。

### 002-brewfile.sh

`Brewfile` に定義されたパッケージを `brew bundle` でインストールします。

### 100-gh-extensions.sh

GitHub CLI の拡張機能をインストールし、関連ツールを追加します。

- `gh-q`（HikaruEgashira/gh-q）拡張機能をインストール
- `gh-infra`（babarot/gh-infra）拡張機能をインストール（`.github/settings.yml` による宣言的リポジトリ設定に使用。詳細は [gh-infra](./gh-infra.md) を参照）
- `fd`（高速ファイル検索ツール）を Homebrew でインストール

### 100-ghostty.sh

Ghostty ターミナルエミュレータをインストールし、terminfo を設定します（未インストールの場合）。

- macOS: Homebrew cask からインストール
- Linux: インストールスクリプトで導入
- macOS では `/Applications/Ghostty.app` の terminfo を `~/.terminfo/` へコピー（`xterm-ghostty` 認識のため）

### 100-lazyvim.sh

LazyVim (Neovim 設定フレームワーク) の依存関係を設定します。

### 100-mise.sh

mise で管理するツール群をインストールします（`mise install`）。

### 100-sheldon.sh

sheldon と starship を Homebrew でインストールし、プラグインをロックファイルに従ってセットアップします。

- `sheldon` と `starship` を Homebrew でインストール
- `sheldon lock` でプラグインをインストール

### 100-tmux.sh

tmux Plugin Manager (tpm) をインストールし、プラグインと依存パッケージをセットアップします。

- tpm を `~/.tmux/plugins/tpm/` にクローン（未インストールの場合）
- tpm でプラグインをインストール
- 共通パッケージを Homebrew でインストール: `bash`, `bc`, `coreutils`, `gawk`, `gh`, `git`, `jq`
- macOS 追加: `glab`, `gsed`, `nowplaying-cli`, `font-noto-sans-symbols-2`
- Linux 追加: `playerctl`

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
