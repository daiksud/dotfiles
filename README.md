# dotfiles

macOS / Ubuntu (Codespaces) で統一された開発環境を再現するための dotfiles です。

## セットアップ

```bash
git clone https://github.com/daiksud/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash install.sh
```

## 含まれるもの

| カテゴリ | 内容 |
|---|---|
| シェル | Zsh + Starship プロンプト + sheldon プラグイン |
| エディタ | Neovim (LazyVim) |
| ターミナル | Ghostty + tmux |
| ツール管理 | Homebrew + mise |
| Git | マルチアカウント自動切り替え (gh-config-dir) + SSH 署名 |
| CLI | gh, fzf, ripgrep, lazygit, jq |

## 仕組み

`install_map.json` にシンボリックリンクの対応表を定義し、`install.sh` がそれに従ってリンクを作成します。

```json
{
  "links": {
    "zshrc": "~/.zshrc",
    "nvim": "~/.config/nvim",
    "starship.toml": "~/.config/starship.toml"
  }
}
```

詳細は [ドキュメント](./docs/README.mdx) を参照してください。

## 対応プラットフォーム

- macOS (Apple Silicon)
- Ubuntu (GitHub Codespaces)

## ドキュメント

- [ガイド](./docs/guides/README.md) — セットアップから日常的な使い方まで
- [リファレンス](./docs/reference/README.md) — 設定ファイル・ツール一覧の詳細
- [開発者向け](./docs/development/README.md) — リポジトリ構造・カスタマイズ・ADR
