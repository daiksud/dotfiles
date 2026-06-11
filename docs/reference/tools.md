# ツール一覧

Brewfile で管理しているツールの一覧と用途です。

## CLI ツール

| パッケージ | 用途                                           |
| ---------- | ---------------------------------------------- |
| `gcc`      | Homebrew ビルド依存                            |
| `fish`     | Fish shell（サブシェル用）                     |
| `fzf`      | ファジーファインダー（ファイル選択、履歴検索） |
| `gh`       | GitHub CLI                                     |
| `git`      | バージョン管理                                 |
| `jq`       | JSON プロセッサ                                |
| `lazygit`  | Git の TUI クライアント                        |
| `lua`      | Lua ランタイム（Neovim プラグイン用）          |
| `luarocks` | Lua パッケージマネージャ                       |
| `mise`     | 開発ツールバージョン管理                       |
| `neovim`   | テキストエディタ                               |
| `ripgrep`  | 高速テキスト検索                               |
| `rtk`      | LLM トークン削減 CLI プロキシ                  |
| `sheldon`  | Zsh プラグインマネージャ                       |
| `starship` | クロスシェルプロンプト                         |
| `tmux`     | ターミナルマルチプレクサ                       |
| `wget`     | HTTP ダウンローダ                              |

## GUI アプリケーション（cask）

| パッケージ             | 用途                                   |
| ---------------------- | -------------------------------------- |
| `copilot-cli`          | GitHub Copilot CLI                     |
| `font-moralerspace-hw` | プログラミング用フォント（macOS のみ） |

## ツールの追加

`Brewfile` にエントリを追加し、`install.sh` を再実行するか `brew bundle` を直接実行します。

```bash
echo 'brew "new-tool"' >> Brewfile
brew bundle --file=Brewfile
```
