# install_map.json

シンボリックリンクの対応表ファイルの仕様です。

## 場所

リポジトリルートの `install_map.json`

## 形式

```json
{
  "links": {
    "<source>": "<target>"
  }
}
```

## フィールド定義

### links

シンボリックリンクのマッピングを定義するオブジェクトです。

| キー | 型 | 説明 |
|---|---|---|
| `<source>` | string | `dotfiles/` ディレクトリ内のファイルまたはディレクトリの相対名 |
| `<target>` | string | リンク先の絶対パス。`~` はホームディレクトリに展開される |

## 現在のエントリ

| Source | Target | 内容 |
|---|---|---|
| `zshrc` | `~/.zshrc` | Zsh 設定ファイル |
| `zsh` | `~/.zsh` | Zsh カスタムプラグインディレクトリ |
| `tmux.conf` | `~/.tmux.conf` | tmux 設定 |
| `gitconfig` | `~/.gitconfig` | Git グローバル設定 |
| `ghostty` | `~/.config/ghostty` | Ghostty ターミナル設定 |
| `mise` | `~/.config/mise` | mise ツールバージョン設定 |
| `nvim` | `~/.config/nvim` | Neovim 設定 (LazyVim) |
| `sheldon` | `~/.config/sheldon` | sheldon プラグイン設定 |
| `starship.toml` | `~/.config/starship.toml` | Starship プロンプト設定 |
| `skills` | `~/.copilot/skills` | Copilot CLI カスタムスキル |
| `copilot-instructions.md` | `~/.copilot/copilot-instructions.md` | Copilot CLI パーソナル指示ファイル |

## 処理の仕様

`install.sh` が `install_map.json` を処理する際の動作:

1. Python3 の `json` モジュールでファイルをパース
2. `~` を `$HOME` に展開
3. 各エントリについて:
   - 宛先の親ディレクトリがシンボリックリンクの場合、実ディレクトリに変換して内容を移行
   - 親ディレクトリが存在しなければ `mkdir -p` で作成
   - 既存のファイル/リンクがあれば `rm -rf` で削除
   - `dotfiles/<source>` → `<target>` のシンボリックリンクを作成

## 制約

- JSON としてバリッドであること（末尾カンマ不可）
