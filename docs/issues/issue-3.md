# Issue 3: Copilot instruction の追加（変更時の issue 記録ルール）

## 日付

2026-04-14

## 背景・目的

変更の経緯や意図を後から追跡できるよう、Copilot が何らかの変更を行う際には必ず `docs/issues/issue-N.md` を同時に作成するルールを設けた。

## 変更内容

- `.github/copilot-instructions.md` を新規作成
  - 変更時に `docs/issues/issue-N.md` を作成するルールを定義
  - issue ファイルのフォーマット（日付・背景・変更内容・備考）を規定

## 備考

このファイル自体が、上記ルールに基づいて作成された最初の issue 記録（issue-3）。
