# Copilot Skills

GitHub Copilot CLI のカスタムスキル管理についてのリファレンスです。

## 概要

スキルは `SKILL.md` ファイルで定義される Copilot CLI の拡張機能です。`~/.copilot/skills/` に配置することで、CLI から呼び出し可能になります。

本リポジトリでは `dotfiles/skills/` にスキルを管理し、`install.sh` 実行時に `~/.copilot/skills` へシンボリックリンクされます。

## ディレクトリ構成

```
dotfiles/skills/
├── create-pr/
│   └── SKILL.md
└── fix-pr/
    └── SKILL.md
```

## スキル一覧

| スキル | 説明 |
|--------|------|
| `create-pr` | 変更内容を理解し、適切なコミットメッセージと Description でドラフト PR を作成する |
| `fix-pr` | CI エラーの修正とレビューコメントへの対処を行い、PR をマージ可能な状態にする |

## SKILL.md のフォーマット

各スキルは以下の構造に従います：

```markdown
---
description: スキルの説明（1行）
name: スキル名
---
# スキル名

（スキルの詳細な説明と手順）
```

### 必須フロントマター

| フィールド | 説明 |
|-----------|------|
| `name` | スキルの識別名（ディレクトリ名と一致させる） |
| `description` | スキルの概要（CLI のスキル一覧に表示される） |

## スキルの呼び出し方

```bash
# CLI から直接呼び出し
copilot -p "/create-pr"

# エイリアスを使う場合
alias create-pr='f() { copilot --model ${COPILOT_MODEL:-claude-sonnet-4.6} -p "/create-pr skill $*"; }; f'
create-pr
```

## 新しいスキルの追加

1. `dotfiles/skills/<skill-name>/SKILL.md` を作成する
2. YAML フロントマターに `name` と `description` を記述する
3. 英語でスキルの手順を記述する
4. `install.sh` を再実行するか、シンボリックリンクが既に存在すれば自動で反映される
