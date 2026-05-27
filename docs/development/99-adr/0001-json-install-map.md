# 0001: シンボリックリンク管理に JSON 対応表を採用

シンボリックリンクの source→target マッピングを `install_map.json` で宣言的に管理する。

## Status

Accepted

## Context

従来はシェルグロブ (`dotfiles/.*`) で `dotfiles/` 以下の全ドットファイルを `~/` に一律リンクしていた。この方式には以下の課題があった:

- `~/.config/X` のようなネストされたパスにリンクする手段がない
- 任意のパス（`~/.copilot/skills` 等）へのリンクに対応できない
- `dotfiles/` 内のファイル名がそのままリンク名になるため、命名の自由度がない
- `.gitconfig` のような特殊処理が増え、スクリプトが複雑化していた

## Decision

リポジトリルートに `install_map.json` を配置し、JSON オブジェクトの key-value でマッピングを定義する。

```json
{
  "links": {
    "zshrc": "~/.zshrc",
    "nvim": "~/.config/nvim",
    "starship.toml": "~/.config/starship.toml"
  }
}
```

パースには Python3 の `json` モジュールを使用する（macOS / Ubuntu ともにプリインストール済み）。

## Alternatives Considered

### シンプルな行形式 (`source:target`)

- 実装が最も簡単
- コメントや構造化が難しい
- エディタのサポート（lint, schema validation）がない

### TOML

- 可読性が高い
- macOS / Ubuntu にプリインストールされたパーサーがない（Python3 の `tomllib` は 3.11+ のみ）

### YAML

- 可読性が高い
- Python3 の標準ライブラリにパーサーがない（`PyYAML` が必要）

### bash 連想配列

- 外部依存ゼロ
- 配列内でのコメントやメンテナンス性が低い
- bash 4.0+ 必須（macOS のデフォルト bash は 3.2）

## Consequences

- エントリの追加・削除が JSON ファイルの編集だけで完結する
- `dotfiles/` 内のファイル名に `.` プリフィックスが不要になり、ファイル一覧が見やすくなる
- Python3 への依存が生じるが、対象プラットフォーム（macOS, Ubuntu）ではシステム標準で利用可能
- JSON はコメントが書けないが、エントリが自明なため問題にならない
