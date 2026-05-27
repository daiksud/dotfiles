# クイックスタート

新しいマシン（または Codespaces）で開発環境を再現する最短手順です。

このガイドを終えると、シェル設定・エディタ (Neovim)・ターミナル (Ghostty)・各種 CLI ツールがすべて揃った状態になります。

## 1. リポジトリをクローンする

```bash
git clone https://github.com/daiksud/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

## 2. インストールスクリプトを実行する

```bash
bash install.sh
```

このスクリプトが行うこと:

1. `install_map.json` に従ってシンボリックリンクを作成
2. Homebrew をインストール（未導入の場合）
3. `Brewfile` のパッケージをインストール
4. 各セットアップスクリプト (`scripts/`) を実行

## 3. シェルを再起動する

```bash
exec zsh
```

Starship プロンプトが表示されれば成功です。

## 動作確認

```bash
# Neovim が起動するか
nvim --version

# mise でツールバージョンが管理されているか
mise list

# gh CLI が認証済みか
gh auth status
```

## 次のステップ

- [インストール詳細](./02-installation.md) — `install.sh` の詳しい動作を知る
- [リンクの追加・変更](./03-managing-links.md) — 新しい設定ファイルを管理対象に加える
- [Git ID の自動切り替え](./04-git-identity.md) — 複数 GitHub アカウントを使い分ける
