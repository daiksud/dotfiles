# ADR

dotfiles の技術選定に関する意思決定記録です。

## ADR とは

ADR（Architecture Decision Record）は、技術選定に関する重要な意思決定を、背景・判断・影響まで含めて記録するための文書です。

## ADR 一覧

| ID                                   | タイトル                                       | Status   |
| ------------------------------------ | ---------------------------------------------- | -------- |
| [0001](./0001-json-install-map.md)   | シンボリックリンク管理に JSON 対応表を採用     | Accepted |
| [0002](./0002-ssh-commit-signing.md) | SSH コミット署名の採用                         | Accepted |
| [0003](./0003-sheldon-starship.md)   | Sheldon + Starship による Oh-My-Zsh の置き換え | Accepted |
| [0004](./0004-gh-q.md)               | gh-q による ghq の置き換え                     | Accepted |
| [0005](./0005-gh-infra.md)           | gh-infra による宣言的リポジトリ設定管理        | Accepted |

## 新しい ADR の書き方

連番付きファイル名で作成し、以下の構成を使います。

```md
# XXXX: 決定のタイトル

その決定が何を扱うのかを 1 行で要約

## Status

Proposed / Accepted / Superseded / Deprecated

## Context

この決定が必要になった背景、課題、制約を書く。

## Decision

何を採用したか、どのように運用するかを書く。

## Alternatives Considered

### 選択肢 A

- 概要
- 採用しなかった理由

## Consequences

- 得られる利点
- 受け入れる制約
```

> [!TIP]
> 代替案を不採用とした理由は詳細に記録してください。AI アシスタントはセッション間でコンテキストを失うため、ADR が「なぜその選択をしたのか」を再取得する唯一の手段になります。
