# mise

開発ツールバージョン管理（mise）の設定リファレンスです。

## グローバル設定

グローバル設定（`~/.config/mise/config.toml`）は dotfiles では管理しません。セットアップ時に `scripts/100-mise.sh` が `mise settings` コマンドで自動的に設定します。

```bash
# 100-mise.sh が実行するコマンド（冪等）
mise settings set github.credential_command "gh auth token"
```

これにより `~/.config/mise/config.toml` はマシンごとに mise が管理するファイルとなり、`mise use -g <tool>` で追加したプライベートツールなども自由に記述できます。

### `[settings.github]`

| キー                 | 値                | 説明                                            |
| -------------------- | ----------------- | ----------------------------------------------- |
| `credential_command` | `"gh auth token"` | GitHub API アクセスに `gh` の認証トークンを使用 |

## リポジトリローカル設定

### `mise.toml`（リポジトリルート）

dotfiles リポジトリ自体の開発環境を定義します。

| ツール | バージョン | 説明                                   |
| ------ | ---------- | -------------------------------------- |
| `bun`  | `latest`   | Bun ランタイム（ドキュメントビルド用） |

`[hooks]` セクションで `postinstall = "bun install --frozen-lockfile"` が設定されており、`mise install` 後に依存関係が自動インストールされます。

### `[settings]`（`mise.toml`）

| キー           | 値     | 説明                                 |
| -------------- | ------ | ------------------------------------ |
| `lockfile`     | `true` | ロックファイルを生成（再現性のため） |
| `experimental` | `true` | 実験的機能を有効化                   |

## シェル統合

`.zshrc` で `eval "$(mise activate zsh)"` により有効化。`cd` 時にプロジェクトの `.mise.toml` や `.tool-versions` に応じてツールバージョンが自動切り替わる。

## ツールの追加

```bash
# グローバルに追加（~/.config/mise/config.toml に書き込まれる）
mise use -g python@latest

# ツールバージョンを確認
mise ls --current
```

