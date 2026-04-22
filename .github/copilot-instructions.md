# Copilot Instructions

## コミットメッセージ

- **英語**で記述する
- **Conventional Commits** 形式に従う: `<type>(<scope>): <description>`
  - 例: `feat(starship): add SSH indicator to prompt`
  - 主な type: `feat`, `fix`, `docs`, `refactor`, `chore`

## 変更時のドキュメント記録

コードや設定ファイルに何らかの変更を行うときは、**必ず同時に** `docs/issues/issue-N.md` を作成すること。

### ルール

- `N` は既存の issue ファイルの最大番号 + 1 とする（例: `issue-1.md`, `issue-2.md`, ...）
- 変更のコミットと同じタイミングで作成・コミットする
- 変更が複数ファイルにまたがる場合でも、1 つの issue に統合してよい
- **1 ユーザー指示ごとに issue を作るのではなく、一連の作業（最初の指示＋それへの修正・改善の指示）をまとめて 1 issue にする**
  - 例: 「機能Aを追加して」→「表示がおかしい」→「さらに調整して」は 1 issue にまとめる
  - 独立した別テーマの指示は別 issue にする

### `docs/issues/issue-N.md` のフォーマット

```markdown
# Issue N: <タイトル>

## 日付

YYYY-MM-DD

## 背景・目的

なぜこの変更が必要か、何を解決しようとしているかを記述する。

## 変更内容

- 変更したファイルと変更の概要を箇条書きで記述する

## 備考

追加の注意点や参考リンクなどがあれば記述する。
```
