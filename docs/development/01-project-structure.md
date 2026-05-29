# プロジェクト構成

リポジトリの主要ディレクトリとファイルの役割を整理します。

## 全体像

```text
.
├── install.sh              # メインセットアップスクリプト
├── install_map.json        # シンボリックリンク対応表
├── Brewfile                # Homebrew パッケージ定義
├── dotfiles/               # シンボリックリンク元ファイル群
│   ├── zshrc               # -> ~/.zshrc
│   ├── zsh/                # -> ~/.zsh（カスタムプラグイン）
│   ├── tmux.conf           # -> ~/.tmux.conf
│   ├── gitconfig           # -> ~/.gitconfig
│   ├── ghostty/            # -> ~/.config/ghostty
│   ├── mise/               # -> ~/.config/mise
│   ├── nvim/               # -> ~/.config/nvim (LazyVim)
│   ├── sheldon/            # -> ~/.config/sheldon
│   ├── starship.toml       # -> ~/.config/starship.toml
│   ├── skills/             # -> ~/.copilot/skills（Copilot スキル）
│   └── copilot-instructions.md # -> ~/.copilot/copilot-instructions.md
├── scripts/                # セットアップスクリプト群
│   ├── 000-codespace.sh
│   ├── 001-homebrew.sh
│   ├── 002-brewfile.sh
│   └── 100-*.sh
├── docs/                   # ドキュメント
│   ├── README.mdx
│   ├── guides/
│   ├── reference/
│   └── development/
├── .devcontainer/          # Codespaces 設定
├── .docusaurus/            # Docusaurus サイト構築
├── .github/
│   ├── copilot-instructions.md
│   └── workflows/docs.yml
├── mise.toml               # リポジトリローカルの mise 設定
├── package.json            # ドキュメントビルド用スクリプト
├── .gitignore              # 追跡しない生成物やローカルファイルの定義
├── .editorconfig
└── LICENSE
```

## 主要ファイルの役割

| パス               | 役割                                                             | 変更するタイミング                             |
| ------------------ | ---------------------------------------------------------------- | ---------------------------------------------- |
| `install.sh`       | セットアップのエントリポイント。リンク作成とスクリプト実行を統括 | リンク処理やスクリプト実行ロジックを変えるとき |
| `install_map.json` | シンボリックリンクの対応表                                       | リンク先を追加・変更するとき                   |
| `Brewfile`         | Homebrew で管理するパッケージ一覧                                | ツールを追加・削除するとき                     |
| `dotfiles/`        | シンボリックリンクされる設定ファイル群                           | 各ツールの設定を変えるとき                     |
| `scripts/`         | セットアップスクリプト群                                         | ツールのインストール手順を変えるとき           |
| `.devcontainer/`   | GitHub Codespaces のコンテナ定義                                 | Codespaces 環境を変えるとき                    |
| `.gitignore`       | Git で追跡しないファイルの除外設定                               | `node_modules/` などの生成物を追加するとき     |

## どのファイルを一緒に触るべきか

### 新しいツールを追加するとき

1. `Brewfile` — パッケージ追加
2. `dotfiles/<config>` — 設定ファイル配置
3. `install_map.json` — リンクエントリ追加
4. `docs/reference/tools.md` — ツール一覧更新
5. 必要に応じて `scripts/100-<tool>.sh` — セットアップスクリプト追加

### Zsh プラグインを追加するとき

1. `dotfiles/zsh/<name>.zsh` — プラグイン作成（`.zshrc` は編集不要、自動 source される）
2. `docs/reference/zsh/plugins.md` — 一覧更新
