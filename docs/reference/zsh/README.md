# Zsh

Zsh シェル設定のリファレンスです。

## ファイル

| ソース | リンク先 | 内容 |
|--------|---------|------|
| `dotfiles/zshrc` | `~/.zshrc` | メイン設定ファイル |
| `dotfiles/zsh/` | `~/.zsh/` | カスタムプラグインディレクトリ |

## .zshrc の構成

`.zshrc` は以下の順序で処理される:

1. **tmux 自動起動** — tmux セッションに接続/作成
2. **Homebrew** — シェル環境変数を設定
3. **compinit** — 補完システムを初期化（sheldon より先に必要）
4. **Emacs キーバインド** — `bindkey -e`
5. **Sheldon** — プラグインを読み込み
6. **History 設定** — 履歴のオプション
7. **Directory 設定** — `auto_cd`, `auto_pushd`
8. **補完スタイル** — 大小文字・ハイフン非区別
9. **EDITOR** — `nvim`
10. **Starship** — プロンプトを初期化
11. **mise** — ランタイムバージョン管理を有効化
12. **カスタム関数** — `~/.zsh/*.zsh` をすべて source

## History 設定

| オプション | 説明 |
|-----------|------|
| `extended_history` | タイムスタンプと実行時間を記録 |
| `hist_ignore_all_dups` | 重複を完全に除去 |
| `hist_ignore_dups` | 直前と同じコマンドを記録しない |
| `hist_ignore_space` | スペース始まりのコマンドを記録しない |
| `hist_reduce_blanks` | 余分な空白を除去 |
| `hist_verify` | 履歴展開をすぐ実行せず表示 |
| `share_history` | セッション間で履歴を共有 |

## Directory 設定

| オプション | 説明 |
|-----------|------|
| `auto_cd` | ディレクトリ名だけで `cd` |
| `auto_pushd` | `cd` 時に自動で `pushd` |
| `pushd_ignore_dups` | ディレクトリスタックの重複を除去 |

## 補完スタイル

```zsh
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}'
```

大文字小文字とハイフン/アンダースコアを区別せずに補完する。
