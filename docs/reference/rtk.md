# RTK

RTK はシェルコマンドの出力をフィルタリング・圧縮し、LLM が消費するトークンを削減する CLI プロキシです。

## ファイル

| dotfiles | リンク先 |
|---|---|
| `dotfiles/copilot-hooks/rtk-rewrite.json` | `~/.copilot/hooks/rtk-rewrite.json` |
| `dotfiles/copilot-instructions.md`（RTK ブロック含む） | `~/.copilot/copilot-instructions.md` |

## セットアップ

### インストール

```bash
brew install rtk
```

### GitHub Copilot 向けフック（グローバル）

```bash
rtk init --global --copilot
```

`~/.copilot/hooks/rtk-rewrite.json` と `~/.copilot/copilot-instructions.md` の RTK ブロックを生成します。
このリポジトリでは hook ファイルを `dotfiles/copilot-hooks/rtk-rewrite.json` として管理し、`install.sh` でシンリンクを作成します。

## 使い方

コマンドの先頭に `rtk` を付けるだけです。

```bash
# 通常コマンドの代わりに使う
rtk git status
rtk git log -10
rtk cargo test
rtk docker ps
```

フックが有効な場合、GitHub Copilot CLI は自動的に `rtk` 経由でコマンドを実行します（手動プレフィックス不要）。

## メタコマンド

```bash
rtk gain              # トークン削減量のダッシュボード
rtk gain --history    # コマンドごとの削減履歴
rtk discover          # rtk 未使用コマンドの検出
rtk proxy <cmd>       # フィルタリングなしで実行（使用量のみ記録）
rtk init --show       # フックの状態確認
```

## アンインストール

```bash
rtk init --uninstall --global --copilot
```

`~/.copilot/hooks/rtk-rewrite.json` と `copilot-instructions.md` の RTK ブロックのみ削除します。他のファイルには影響しません。

## 参考

- [RTK 公式サイト](https://www.rtk-ai.app/)
- [GitHub Copilot 向け設定](https://www.rtk-ai.app/docs/getting-started/supported-agents/#github-copilot-vs-code-chat--cli)
