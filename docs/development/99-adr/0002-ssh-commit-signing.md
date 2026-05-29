# ADR 0002: SSH コミット署名の採用

## Status

Accepted

## Context

Git コミット署名は真正性を保証し、GitHub の「Verified」バッジを有効にする。従来の方式は GPG 鍵だが、以下の課題がある:

- 別途鍵の生成と管理が必要
- macOS では `gpg` と `pinentry` の追加インストールが必要
- 鍵の有効期限管理が煩雑
- GitHub への鍵登録が認証鍵とは別に必要

開発者は GitHub 認証用に SSH 鍵をすでに持っているため、これを署名にも流用すればオーバーヘッドをゼロにできる。

## Decision

既存の ed25519 SSH 鍵を使った SSH ベースのコミット署名を採用する。

グローバル gitconfig に設定:

- `commit.gpgsign = true` — すべてのコミットを自動署名
- `gpg.format = ssh` — GPG ではなく SSH 方式を使用
- `gpg.ssh.allowedSignersFile = ~/.ssh/allowed_signers` — ローカル署名検証用

リポジトリごとの `user.signingkey` は `gh-config-dir.zsh` がアクティブな GitHub アカウントに応じて自動設定する（`~/.ssh/<login>.pub`）。

## Alternatives Considered

### GPG 署名

不採用 — 追加ツール（`gpg`, `pinentry`）のインストール、独立した鍵ライフサイクル管理が必要で、SSH 署名に比べて実用上の利点がない。

### 署名なし

不採用 — マルチアカウント運用では「Verified」バッジがコミットの信頼性を示す重要な手段であり、SSH 鍵の流用で実質コストゼロで実現できる。

## Consequences

- SSH 鍵を持つ開発者にとって追加セットアップがゼロ
- `gh-config-dir.zsh` によりマルチアカウント署名が自動で動作
- 各アカウントの `~/.ssh/<login>.pub` を GitHub の Signing Keys に登録する必要がある
- `allowed_signers` は自動管理され、ローカルでの署名検証が可能
