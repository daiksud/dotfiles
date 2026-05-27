# ADR 0003: Sheldon + Starship による Oh-My-Zsh の置き換え

## Status

Accepted

## Context

Oh-My-Zsh はプラグイン管理・テーマ・補完を一括提供するモノリシックなフレームワーク。以下の問題があった:

- フレームワーク全体（`lib/*.zsh`）をロードするためシェル起動が遅い
- プラグイン管理が OMZ のディレクトリ構造に依存し、宣言的でない
- テーマが OMZ 内部の関数に依存しており、他のシェルに移植できない

目標は、高速な起動・宣言的で最小限のプラグイン管理・ポータブルなプロンプトの実現。

## Decision

Oh-My-Zsh を 2 つの専門ツールで置き換える:

- **Sheldon** — TOML 設定による宣言的プラグインマネージャ（`~/.config/sheldon/plugins.toml`）
- **Starship** — Rust 製クロスシェルプロンプト（`~/.config/starship.toml`）

### プラグイン読み込み

必要なプラグインのみを `plugins.toml` に宣言する。OMZ の git プラグインは `ohmyzsh/ohmyzsh` リポジトリの `plugins/git` ディレクトリを直接参照する形で継続利用。

### 重要な制約: compinit の順序

`compinit` は `sheldon source` の**前に**呼ぶ必要がある。fzf-tab など `compdef` を使うプラグインが正しく動作するため。

## Alternatives Considered

### Oh-My-Zsh を維持

不採用 — 不要なオーバーヘッドと非宣言的なプラグイン管理。

### Zinit / Antidote

検討した — いずれも有力な zsh プラグインマネージャ。Sheldon を選んだ理由は Rust 実装（高速）、TOML 設定（可読性）、ロックファイル機構。

### Pure / Powerlevel10k

プロンプトとして検討した — Starship を選んだ理由はクロスシェル互換性とシンプルな TOML 設定。

## Consequences

- シェル起動が高速化（宣言したプラグインのみロード）
- `plugins.toml` が zsh プラグインの単一の信頼源
- Starship の設定は bash, fish など他シェルでも再利用可能
- Brew, gh, mise の OMZ プラグインは削除（これらのツールは独自のシェル統合を持つため）
