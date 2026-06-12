# gh-infra

`.github/settings.yml` による宣言的なリポジトリ設定管理のリファレンスです。

## 概要

[gh-infra](https://github.com/babarot/gh-infra)（`babarot/gh-infra`）は、GitHub リポジトリの設定を YAML で宣言的に管理する GitHub CLI 拡張です。Terraform に似ていますが、ステートファイルは不要で、GitHub 自体が信頼できる情報源になります。

このリポジトリでは、ラベル・マージ戦略・ブランチ保護（ruleset）・セキュリティ設定などを `.github/settings.yml` に記述し、UI を手動操作せずに再現可能な形で管理します。

## ファイル

`.github/settings.yml`（シンボリックリンクはせず、リポジトリ内に直接配置）

## 主要な設定

`.github/settings.yml` の `spec` で定義している主な項目です。

| セクション       | 内容                                                                                   |
| ---------------- | -------------------------------------------------------------------------------------- |
| `labels`         | Issue / PR ラベルの定義（名前・説明・色）                                               |
| `features`       | issues / projects / wiki / discussions / pull_requests の有効・無効                    |
| `merge_strategy` | squash マージのみ許可、auto-merge とマージ後のブランチ自動削除を有効化                  |
| `security`       | 脆弱性アラート・自動セキュリティ修正・プライベート脆弱性報告を有効化                    |
| `rulesets`       | デフォルトブランチの保護（後述）                                                        |
| `actions`        | GitHub Actions の許可範囲とデフォルトの `workflow_permissions`                          |

### デフォルトブランチの ruleset

`rulesets` でデフォルトブランチに以下を強制しています。

| ルール                     | 値      | 説明                                       |
| -------------------------- | ------- | ------------------------------------------ |
| `required_linear_history`  | `true`  | マージコミットを禁止（直線的な履歴を強制） |
| `required_signatures`      | `true`  | 署名付きコミットを必須化                   |
| `non_fast_forward`         | `true`  | 強制プッシュを禁止                         |
| `deletion`                 | `true`  | ブランチ削除を禁止                         |
| `creation`                 | `false` | ブランチ作成の制限はしない                 |

> [!IMPORTANT]
> `required_linear_history` が有効なため、デフォルトブランチにはマージコミットをプッシュできません。ローカルで取り込む場合は fast-forward マージ（`git merge --ff-only`）を使用してください。

## セットアップ

`gh-infra` 拡張は `scripts/100-gh-extensions.sh` で自動インストールされます（[スクリプト一覧](./scripts.md) を参照）。手動でインストールする場合:

```bash
gh extension install babarot/gh-infra
```

## 使い方

`plan` で差分を確認してから `apply` で適用します。`.github/settings.yml` を明示的に指定します。

```bash
# YAML と現在の GitHub 設定の差分を表示
gh infra plan .github/settings.yml

# 差分を適用（確認プロンプトあり）
gh infra apply .github/settings.yml

# YAML の構文・スキーマを検証
gh infra validate .github/settings.yml
```

既存リポジトリの設定を YAML として書き出す場合は `import` を使います。

```bash
gh infra import daiksud/dotfiles > .github/settings.yml
```

## コマンド一覧

| コマンド          | 説明                                       |
| ----------------- | ------------------------------------------ |
| `plan [path]`     | YAML と現在の GitHub 設定の差分を表示       |
| `apply [path]`    | 差分を適用（確認プロンプトあり）           |
| `import <repo>`   | 既存リポジトリの設定を YAML として書き出す |
| `validate [path]` | YAML の構文・スキーマを検証                 |

## 参考

- [gh-infra リポジトリ](https://github.com/babarot/gh-infra)
- [gh-infra ドキュメント](https://babarot.github.io/gh-infra/introduction/getting-started/)
- 技術選定の背景は [ADR 0005](../development/99-adr/0005-gh-infra.md) を参照
