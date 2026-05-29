# Sheldon

Zsh プラグインマネージャ（sheldon）の設定リファレンスです。

## ファイル

`dotfiles/sheldon/plugins.toml` → `~/.config/sheldon/plugins.toml`

## トップレベル設定

```toml
shell = "zsh"
```

## テンプレート

```toml
[templates]
fpath = "fpath=(\"{{ dir }}\" $fpath)"
```

`apply = ["fpath"]` を指定したプラグインは source せず `fpath` に追加するのみ（補完定義の登録用）。

## プラグイン一覧

| プラグイン名                   | リポジトリ                                   | 説明                                             |
| ------------------------------ | -------------------------------------------- | ------------------------------------------------ |
| `fzf-tab`                      | `Aloxaf/fzf-tab`                             | zsh 標準補完を fzf に置き換え                    |
| `ohmyzsh-lib-git`              | `ohmyzsh/ohmyzsh` (lib/git.zsh)              | git プラグインが依存するユーティリティ関数       |
| `ohmyzsh-git`                  | `ohmyzsh/ohmyzsh` (plugins/git)              | Git エイリアス群（`gst`, `gco`, `gcm`, `gp` 等） |
| `zsh-completions`              | `zsh-users/zsh-completions`                  | 追加の補完定義（fpath のみ）                     |
| `zsh-autosuggestions`          | `zsh-users/zsh-autosuggestions`              | Fish 風の入力候補表示                            |
| `zsh-autopair`                 | `hlissner/zsh-autopair`                      | 括弧・クォートの自動ペア                         |
| `fast-syntax-highlighting`     | `zdharma-continuum/fast-syntax-highlighting` | コマンドのシンタックスハイライト                 |
| `zsh-history-substring-search` | `zsh-users/zsh-history-substring-search`     | 入力中の文字列で履歴をサブストリング検索         |

## 読み込み順序の制約

1. **compinit が先** — `.zshrc` で `compinit` を `sheldon source` より前に呼ぶ（`compdef` を使うプラグインが動作するため）
2. **syntax highlighting の後に history-substring-search** — sheldon は TOML の定義順に source するため、`fast-syntax-highlighting` を先に書く

## プラグインの追加

```toml
[plugins.new-plugin]
github = "author/new-plugin"
```

追加後:

```bash
sheldon lock --update
```
