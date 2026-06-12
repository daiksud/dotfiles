# ADR 0005: gh-infra による宣言的リポジトリ設定管理

`.github/settings.yml` と `gh-infra` 拡張でリポジトリ設定をコード管理する。

## Status

Accepted

## Context

リポジトリのラベル・マージ戦略・ブランチ保護・セキュリティ設定などを GitHub の Web UI で手動管理すると、以下の課題がある。

- 設定がバージョン管理されず、いつ・なぜ変更したかが追えない
- 同じ設定を再現・移植できない
- レビューやプレビューなしに即時反映される

これらを宣言的に、かつ `gh` CLI のエコシステム内で管理したい。

## Decision

`.github/settings.yml` にリポジトリ設定を YAML で記述し、`gh-infra`（`babarot/gh-infra`）拡張で適用する。

- `scripts/100-gh-extensions.sh` で `gh extension install babarot/gh-infra` を実行
- `gh infra plan` で差分を確認してから `gh infra apply` で反映
- ステートファイルを持たず、GitHub の現在状態を信頼できる情報源とする

## Alternatives Considered

### Terraform GitHub Provider

検討した — GitHub-as-Code の定番だが、プロバイダのインストール・HCL・ステートファイル・ステートロックが必要で、個人リポジトリにはオーバーヘッドが大きい。

### Probot Settings / GitHub App 系

不採用 — GitHub App やサーバーの運用が必要で、`plan` による事前プレビューがなく即時適用される。

### Web UI で手動管理（現状維持）

不採用 — バージョン管理・再現性・変更履歴が得られず、本 ADR の動機を満たさない。

## Consequences

- `.github/settings.yml` がリポジトリ設定の信頼できる情報源になる
- `gh-infra` 拡張のインストールが前提になる（`scripts/100-gh-extensions.sh` で自動化）
- 設定変更は `plan` → `apply` のフローで適用し、差分をレビューできる
- デフォルトブランチに `required_linear_history` / `required_signatures` を強制するため、マージコミットや未署名コミットはプッシュできない
- 運用方法は [reference/gh-infra.md](../../reference/gh-infra.md) に記載
