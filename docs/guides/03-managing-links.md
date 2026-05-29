# リンクの追加・変更

`install_map.json` を編集して、シンボリックリンクの対応関係を管理する方法を説明します。

## install_map.json の形式

```json
{
  "links": {
    "<source>": "<target>",
    ...
  }
}
```

| フィールド | 説明                                                       |
| ---------- | ---------------------------------------------------------- |
| `<source>` | `dotfiles/` ディレクトリ内のファイルまたはディレクトリ名   |
| `<target>` | リンク先の絶対パス（`~` はホームディレクトリに展開される） |

## リンクを追加する

### 例: Copilot skills を管理する

1. 設定ファイルを `dotfiles/` に配置する:

```bash
cp -r ~/.copilot/skills dotfiles/skills
```

2. `install_map.json` にエントリを追加する:

```json
{
  "links": {
    "skills": "~/.copilot/skills"
  }
}
```

3. `install.sh` を再実行する:

```bash
bash install.sh
```

### 例: ~/.config 以下のアプリを追加する

```bash
cp -r ~/.config/lazygit dotfiles/lazygit
```

```json
{
  "links": {
    "lazygit": "~/.config/lazygit"
  }
}
```

## リンクを削除する

`install_map.json` から該当エントリを削除し、必要に応じて `dotfiles/` 内のファイルも削除します。

> [!NOTE]
> `install.sh` はエントリにないリンクを自動削除しません。既存のシンボリックリンクは手動で `rm` してください。

## 宛先の親ディレクトリについて

`install.sh` は宛先の親ディレクトリを自動作成します（`mkdir -p`）。`~/.config/` が存在しなくても問題ありません。

旧環境で `~/.config` がシンボリックリンクだった場合は、実ディレクトリに変換してから内容を移行します。
