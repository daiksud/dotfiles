---
name: pr-create
description: Pull Request を作成する際に使用するスキル。/pr create が呼び出されたときも含む。リポジトリの規約に従ってドラフト PR を作成します。
---

# pr-create

## 概要

ドラフトの Pull Request (PR) を作成するスキルです。
ステージされたファイルやコミット済みの変更内容を理解し、適切なコミットメッセージと PR Description を作成して PR を作成します。

## 使用タイミング

- 「PR を作成して」と依頼されたとき
- GitHub Copilot CLI で `/pr-create` や `/pr create` が呼び出されたとき

## 手順

### ステップ 1: 対応する Task (GitHub Issue) を確認する

- まず最初に、この変更に対応する GitHub Issue (Task) があるかを確認する
  - スキル呼び出し時のコンテキスト、ブランチ名、コミットメッセージなどから関連 Issue を推測する
  - 推測できる場合は `gh issue view <番号> --comments` で内容を確認し、変更内容と整合しているか検証する
    - Issue の Description だけでなくコメントも読み、変更の意図・経緯・議論の流れを把握する
- 対応する Task が簡単に推測できない場合は、ユーザーに尋ねる
  - 例: 「この変更に対応する Task (Issue) はありますか？ある場合は番号を教えてください」
- 対応する Task が存在しない場合は、ユーザーに作成を促す
  - Task を作成する場合は `gh issue create` を提案する
  - Task を作成したら、その番号を控えておき、後続のステップ（PR Description の `closes #XXX`）で使用する

### ステップ 2: 変更内容を深く理解する

- `git diff --staged` または `git diff origin/main..` を実行し、差分全体を確認する
- 各ファイルの差分を読み、**何が**・**なぜ**変更されたかを理解する
  - 必ず origin/main に対してどのような変更が加わるのかにフォーカスすること
- スキル呼び出し時に渡されたコンテキストや理由を考慮する
- 変更内容や経緯を推測する際は、対応する Issue の Description やコメントも参考にすること
- 新規ファイルの場合、ファイル全体を読んで目的と役割を把握する
- 変更が複数の論理単位にまたがる場合、複数コミットへの分割を検討する

### ステップ 3: コミットメッセージを作成してコミットする

- `git diff --staged --quiet` を実行し、終了コードが 1（ステージされたファイルあり）の場合のみコミットする
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) 形式に従う
- コミットメッセージは英語で書く
- `git log --no-merges --oneline -100` で直近のコミットを確認し、リポジトリの慣習に合わせる
- **コミットの件名は変更内容を具体的に記述すること**
  - 悪い例: `docs: apply staged changes`（何が変わったか不明）
  - 悪い例: `feat: update files`（曖昧すぎる）
  - 良い例: `feat: allow provided config object to extend other configs`
  - 良い例: `fix(github): pin terraform-provider-github version to 6.6.0`
- scope は影響範囲を示す（ディレクトリ名、アクション名など）
- 命令形（add, fix, update）を使い、意図を明確にする
- 必要に応じて body に補足説明を追加する
- レビューや論理的な分離に役立つ場合は複数コミットに分割してよい

### ステップ 4: feature ブランチにプッシュする

- 現在 main にいる場合は feature ブランチを作成してチェックアウトする
- ブランチ名は変更内容を反映する（例: `feat/add-pr-create-skill`, `fix/pin-terraform-provider-github-660`）
- `git push --set-upstream origin <branch>` でプッシュする
- ローカルの main ブランチにコミットしてしまっている場合は、origin/main に合わせて元に戻す

### ステップ 5: PR Description を作成してドラフト PR を作る

- `.github/pull_request_template.md` が存在する場合、その構造に従うこと
- PR 本文は日本語で記述すること
- Description に含める内容:
  - **目的:**
    - この PR が達成すること（「何を」だけでなく「なぜ」も含める）
    - ステップ 1 で確認・作成した Task がある場合は、`closes #XXX` を含めること
  - **背景:**
    - この変更が必要になった理由やコンテキスト
    - 必ず origin/main に対してどのような変更がなされるのかにフォーカスして説明すること
- `CONTRIBUTING.md` が存在する場合、そのガイドラインに従うこと
- 以下のアンチパターンを避けること
  - 「変更されたファイル」をそのまま列挙する（diff から明らかなことを書かない）
  - 理由を示さない高コンテキストな説明
- `gh pr create --draft` で PR を作成する
  - **PR タイトル**は英語で、[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) 形式: `<type>(<scope>): <description>`
  - PR 内容に適したラベルを設定する（例: `feature`, `bug`, `documentation`）

### ステップ 6: リクエストしたユーザーをアサインする

- スキルを呼び出したユーザーを PR の Assignee に設定する
- `gh pr edit <PR_NUMBER> --add-assignee <username>` を使用する

### ステップ 7: Issue (Task) の Description を最終的な変更内容に合わせる

- 対応する Task がある場合、その Description を最終的な Pull Request の変更内容に合わせた方針へ更新する
- 試行錯誤の末、Issue の Description の方針と実際の変更内容が異なっていた場合:
  - 当初の計画（元の Description）は `gh issue comment <番号>` でコメントとして切り出して残す
  - その上で Issue の Description を `gh issue edit <番号> --body` で実際の変更内容に合わせた方針に更新する
- Description と実際の変更内容が当初から一致している場合は、無理に書き換える必要はない

## 出力

作成されたドラフト PR の URL をブラウザで開く。
