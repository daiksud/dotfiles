# スキルの開発

Copilot CLI カスタムスキルを新規作成・変更するためのガイドです。

## 新しいスキルを作る

### 1. ディレクトリとファイルを作成

```bash
mkdir dotfiles/skills/<skill-name>
touch dotfiles/skills/<skill-name>/SKILL.md
```

### 2. SKILL.md を書く

```markdown
---
description: スキルの説明（1行、日本語）
name: skill-name
---

# skill-name

## Overview

What the skill does and why it exists.

## When to Use

- Trigger phrases or conditions

## How to Use

### Step 1: ...

### Step 2: ...

## Output

What the user sees when the skill completes.

## Constraints

- Limitations and failure behavior
```

### 3. 動作確認

シンボリックリンクが設定済みなら、作成した時点でスキルは利用可能です：

```bash
copilot -p "/skill-name"
```

ロードエラーが出る場合はフロントマターの `name` と `description` が正しいか確認してください。

## 記述ルール

| ルール                 | 理由                                      |
| ---------------------- | ----------------------------------------- |
| 日本語で書く           | 本文も description も日本語で統一するため  |
| ステップを具体的に書く | 曖昧だとエージェントが判断に迷う          |
| 制約条件を明示する     | 無限ループや破壊的操作を防ぐ              |
| 出力を定義する         | ユーザーが何を期待できるか明確にする      |

## ファイル配置

```
dotfiles/skills/
└── <skill-name>/
    └── SKILL.md       # 必須: スキル定義ファイル
```

- 1 スキル = 1 ディレクトリ
- ディレクトリ名 = スキル名（ケバブケース）
- 追加ファイル（テンプレートなど）を同ディレクトリに置くことも可能

## インストール

`install_map.json` に `"skills": "~/.copilot/skills"` が登録済みのため、`install.sh` を実行すればシンボリックリンクが作成されます。既にリンクが存在する場合は何もしなくても新しいスキルが認識されます。

## テストのコツ

- スキルを書いたら実際に `copilot -p "/skill-name"` で呼び出して動作を確認する
- エージェントが手順通りに動かない場合は、ステップの記述をより具体的にする
- `Constraints` セクションで失敗時の振る舞い（リトライ回数、停止条件）を定義すると安定性が上がる
