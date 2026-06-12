# mise

開発ツールバージョン管理（mise）の設定リファレンスです。

## ファイル

`dotfiles/mise/config.toml` → `~/.config/mise/config.toml`

## ツール定義

### `dotfiles/mise/config.toml`（グローバル）

グローバル設定ではツールを管理していません。`[settings.github]` のみを定義します。

```toml
[settings.github]
credential_command = "gh auth token"
```

> [!NOTE]
> 以前は `node` / `bun` / `npm:markdownlint-cli2` を mise で管理していましたが、`node` と `bun` は Homebrew（`Brewfile`）管理へ移行し、`markdownlint-cli2` は廃止しました。詳細は [ツール一覧](./tools.md) を参照してください。

### `mise.toml`（リポジトリルート）

dotfiles リポジトリ自体の開発環境を定義します。

| ツール | バージョン | 説明                                   |
| ------ | ---------- | -------------------------------------- |
| `bun`  | `latest`   | Bun ランタイム（ドキュメントビルド用） |

`[hooks]` セクションで `postinstall = "bun install --frozen-lockfile"` が設定されており、`mise install` 後に依存関係が自動インストールされます。

## 設定

### `[settings]`（リポジトリルートの `mise.toml`）

| キー           | 値     | 説明                                 |
| -------------- | ------ | ------------------------------------ |
| `lockfile`     | `true` | ロックファイルを生成（再現性のため） |
| `experimental` | `true` | 実験的機能を有効化                   |

### `[settings.github]`（グローバルの `config.toml`）

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
