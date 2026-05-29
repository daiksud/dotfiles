# スキルの使い方

Copilot CLI のカスタムスキルをすぐに使い始めるためのガイドです。

## 前提

- dotfiles がインストール済み（`install.sh` 実行済み）
- GitHub Copilot CLI がインストール済み

## 使えるスキル

| スキル      | やること                                                           |
| ----------- | ------------------------------------------------------------------ |
| `pr-create` | 今の変更からドラフト PR を自動作成                                 |
| `pr-fix`    | 指定した PR の CI エラー修正・レビュー対応・マージコンフリクト解消 |

## pr-create を使う

変更をステージした状態で：

```bash
copilot -p "/pr-create"
```

変更理由を伝えたい場合：

```bash
copilot -p "/pr-create 認証ロジックのリファクタリング、#42 に関連"
```

インタラクティブセッションでは `/pr create` でも起動する（後述）。

### 何が起きるか

1. 差分を読んでコミットメッセージを考える
2. feature ブランチを作ってプッシュ
3. ドラフト PR を作成
4. あなたを Assignee に設定

## pr-fix を使う

```bash
copilot -p "/pr-fix PR #42"
```

インタラクティブセッションでは `/pr fix` でも起動する（後述）。

### 何が起きるか

1. マージコンフリクトを検出して解消
2. CI の失敗をログから特定して修正（通るまで繰り返し）
3. レビューコメントを確認し、妥当なものは修正
4. ローカルレビューを実施してからプッシュ
5. 各レビューコメントに対応内容をリプライし、スレッドを resolve

モード指定も可能:

```bash
copilot -p "/pr-fix ci #42"        # CI 失敗のみ
copilot -p "/pr-fix feedback #42"  # レビューコメントのみ
copilot -p "/pr-fix conflicts #42" # コンフリクトのみ
```

## /pr create・/pr fix との統合

`install.sh` によって `dotfiles/copilot-instructions.md` が `~/.copilot/copilot-instructions.md` へシンボリックリンクされる。
このファイルには以下の指示が含まれており、インタラクティブセッションで常時ロードされる:

- `/pr create` が呼ばれたら → `pr-create` スキルを使う
- `/pr fix` が呼ばれたら → `pr-fix` スキルを使う

これにより、ビルトインの `/pr` サブコマンドを使っても、定義済みスキルの手順に従った動作になる。

> [!NOTE]
> この統合は Copilot の instruction 読み込みを介した仕組みであり、完全に確定的なバインディングではない。スキルを確実に使わせたい場合は `/pr-create` や `/pr-fix` で直接呼び出すこと。

## エイリアス設定（おすすめ）

`.zshrc` や `.bashrc` に追加：

```bash
alias pr-create='f() { copilot --model ${COPILOT_MODEL:-claude-sonnet-4.6} -p "/pr-create skill $*"; }; f'
alias pr-fix='f() { copilot --model ${COPILOT_MODEL:-claude-sonnet-4.6} -p "/pr-fix skill $*"; }; f'
```

使い方：

```bash
pr-create
pr-fix PR #42
```
