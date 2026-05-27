# mise

開発ツールバージョン管理（mise）の設定リファレンスです。

## ファイル

`dotfiles/mise/config.toml` → `~/.config/mise/config.toml`

## ツール定義

| ツール | バージョン | 説明 |
|--------|-----------|------|
| `node` | `latest` | Node.js ランタイム |
| `npm:markdownlint-cli2` | `latest` | Markdown リンター |

## 設定

### `[settings]`

| キー | 値 | 説明 |
|------|-----|------|
| `lockfile` | `true` | ロックファイルを生成（再現性のため） |
| `http_retries` | `5` | HTTP リクエストのリトライ回数 |
| `http_timeout` | `"20s"` | HTTP タイムアウト |

### `[settings.github]`

| キー | 値 | 説明 |
|------|-----|------|
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
