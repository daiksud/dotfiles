# mise

開発ツールバージョン管理（mise）の設定リファレンスです。

## ファイル

`dotfiles/mise/config.toml` → `~/.config/mise/config.toml`

## ツール定義

### `dotfiles/mise/config.toml`（グローバル）

| ツール                  | バージョン | 説明               |
| ----------------------- | ---------- | ------------------ |
| `node`                  | `latest`   | Node.js ランタイム |
| `bun`                   | `latest`   | Bun ランタイム     |
| `npm:markdownlint-cli2` | `latest`   | Markdown リンター  |

### `mise.toml`（リポジトリルート）

dotfiles リポジトリ自体の開発環境を定義します。

| ツール | バージョン | 説明                                   |
| ------ | ---------- | -------------------------------------- |
| `bun`  | `latest`   | Bun ランタイム（ドキュメントビルド用） |

`[hooks]` セクションで `postinstall = "bun install --frozen-lockfile"` が設定されており、`mise install` 後に依存関係が自動インストールされます。

## 設定

### `[settings]`

| キー           | 値      | 説明                                 |
| -------------- | ------- | ------------------------------------ |
| `lockfile`     | `true`  | ロックファイルを生成（再現性のため） |
| `http_retries` | `5`     | HTTP リクエストのリトライ回数        |
| `http_timeout` | `"20s"` | HTTP タイムアウト                    |

> [!NOTE]
> リポジトリルートの `mise.toml` にも `lockfile = true` と `experimental = true` が設定されています。

### `[settings.github]`

| キー                 | 値                | 説明                                            |
| -------------------- | ----------------- | ----------------------------------------------- |
| `credential_command` | `"gh auth token"` | GitHub API アクセスに `gh` の認証トークンを使用 |

## シェル統合

`.zshrc` で `eval "$(mise activate zsh)"` により有効化。`cd` 時にプロジェクトの `.mise.toml` や `.tool-versions` に応じてツールバージョンが自動切り替わる。

## ツールの追加

```bash
# グローバルに追加
mise use --global python@latest

# config.toml に手動追加
[tools]
python = "latest"
```
