# Starship

クロスシェルプロンプト（Starship）の設定リファレンスです。

## ファイル

`dotfiles/starship.toml` → `~/.config/starship.toml`

## プロンプト構成

Powerline 風のグラデーションセグメントで構成される 2 行プロンプト:

```
[░▒▓ ][directory][git_branch + git_status][languages][time]
[character]
```

### セグメントと配色

| セグメント | 背景色 | 前景色 | 内容 |
|-----------|--------|--------|------|
| アイコン | `#a3aed2` | `#090c0c` | 固定アイコン ` ` |
| directory | `#769ff0` | `#e3e5e5` | カレントディレクトリ（3 階層まで） |
| git_branch / git_status | `#394260` | `#769ff0` | ブランチ名 + ステータス |
| languages | `#212736` | `#769ff0` | Node.js / Bun / Rust / Go / PHP バージョン |
| time | `#1d2230` | `#a0a9cb` | 現在時刻（`HH:MM`） |

## モジュール設定

### directory

| キー | 値 | 説明 |
|------|-----|------|
| `truncation_length` | `3` | 表示する最大ディレクトリ階層数 |
| `truncation_symbol` | `…/` | 省略時の記号 |

特殊ディレクトリの置換:

| ディレクトリ | 表示 |
|-------------|------|
| Documents | `󰈙 ` |
| Downloads | ` ` |
| Music | ` ` |
| Pictures | ` ` |

### git_branch

ブランチシンボル: `` （Nerd Font）

### 言語モジュール

検出された言語のバージョンを表示。すべて同じスタイルで統一:

| モジュール | シンボル |
|-----------|---------|
| `nodejs` | `` |
| `bun` | `` |
| `rust` | `` |
| `golang` | `` |
| `php` | `` |

### time

| キー | 値 | 説明 |
|------|-----|------|
| `disabled` | `false` | 有効 |
| `time_format` | `%R` | `HH:MM` 形式 |
