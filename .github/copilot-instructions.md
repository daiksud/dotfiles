# Copilot Instructions

## コミットメッセージ

- **英語**で書く
- [Conventional Commits](https://www.conventionalcommits.org/) に従う: `<type>(<scope>): <description>`
  - 例: `feat(starship): add SSH indicator to prompt`
  - 種別: `feat`, `fix`, `docs`, `refactor`, `chore`

## ドキュメント構成

`docs/` 以下には Docusaurus で構築された GitHub Flavored Markdown のドキュメントを置く:

- `docs/guides/` — ユーザー向けガイド（セットアップと使い方）
- `docs/reference/` — リファレンス（ツール一覧、設定仕様）
- `docs/development/` — 貢献者向け情報（構成、スタイルガイド）
- `docs/development/99-adr/` — Architecture Decision Records

### ドキュメント対応表

| トピック           | パス                                        | 対象   |
| ------------------ | ------------------------------------------- | ------ |
| クイックスタート   | `docs/guides/01-quick-start.md`             | 利用者 |
| インストール       | `docs/guides/02-installation.md`            | 利用者 |
| リンク管理         | `docs/guides/03-managing-links.md`          | 利用者 |
| Git identity       | `docs/guides/04-git-identity.md`            | 利用者 |
| スキルの使い方     | `docs/guides/06-skills.md`                  | 利用者 |
| Ghostty            | `docs/reference/ghostty.md`                 | 利用者 |
| Git                | `docs/reference/git.md`                     | 利用者 |
| mise               | `docs/reference/mise.md`                    | 利用者 |
| Neovim             | `docs/reference/nvim.md`                    | 利用者 |
| Sheldon            | `docs/reference/sheldon.md`                 | 利用者 |
| Starship           | `docs/reference/starship.md`                | 利用者 |
| tmux               | `docs/reference/tmux.md`                    | 利用者 |
| Zsh                | `docs/reference/zsh/README.md`              | 利用者 |
| Zsh plugins        | `docs/reference/zsh/plugins.md`             | 利用者 |
| install_map.json   | `docs/reference/install-map.md`             | 利用者 |
| Scripts            | `docs/reference/scripts.md`                 | 利用者 |
| Tools (Brewfile)   | `docs/reference/tools.md`                   | 利用者 |
| Copilot Skills     | `docs/reference/skills.md`                  | 利用者 |
| Project structure  | `docs/development/01-project-structure.md`  | 貢献者 |
| Docs style         | `docs/development/02-docs-style.md`         | 貢献者 |
| ADR index          | `docs/development/99-adr/README.md`         | 貢献者 |
| Skills development | `docs/development/03-skills-development.md` | 貢献者 |

編集前に読むべきスタイル参照:

- `docs/development/02-docs-style.md` — ドキュメント執筆スタイルガイド

## 必須ワークフロー

1. コードを編集する前に、`docs/` 配下の関連文書を必ず読む（少なくとも該当セクションの `README` と関連ページ）。
2. ドキュメントを編集する前に、`docs/development/02-docs-style.md` を必ず読んで、ドキュメント方針と規約を理解する。
3. コード、スクリプト、設定を変更するときは、同じ変更内で必ず `docs/` も更新する。変更チェックリストと対象範囲の対応は `docs/development/02-docs-style.md` の "Documentation Strategy" セクションを参照する。
4. 変更後は必ず、ドキュメントの正確性、リンク整合性、現在の実装に対する網羅性を確認する。
5. 現在の文書構成が分かりにくい場合は、必要に応じて再編成する。
6. ドキュメントは常に現在の実装と一致させる。更新を次のコミットに先送りしない。
7. アーキテクチャや技術選定に複数の選択肢がある場合は、必ず `docs/development/99-adr/` に記録する。

## Docusaurus の規約

- ファイル名はサイドバー順のために `01-` 形式の番号プレフィックスを付ける
- セクションディレクトリ（`guides/`, `reference/`, `development/`）には番号プレフィックスを付けない
- 各ディレクトリの `README.md` をインデックスページとする
- リンクは相対パスかつ `.md` 拡張子付きで記述する
- 各ページは `# h1` タイトルで始め、その後に説明段落を置く

## 必須の品質基準

- ドキュメントには **何が変わったか**、**なぜ変わったか**、**どう操作するか** を必ず書く
- 例やコマンドはそのままコピーして使える形にする
- 古い案内や重複した案内は避ける
- 意思決定の記録には明確な理由を含める
