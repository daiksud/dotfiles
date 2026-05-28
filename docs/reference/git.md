# Git

グローバル Git 設定（`~/.gitconfig`）のリファレンスです。

## ファイル

`dotfiles/gitconfig` → `~/.gitconfig`

## 設定一覧

| セクション | キー | 値 | 説明 |
|-----------|------|-----|------|
| `[push]` | `autosetupremote` | `true` | push 時にリモートトラッキングブランチを自動設定 |
| `[push]` | `default` | `current` | 同名のリモートブランチに push |
| `[commit]` | `gpgsign` | `true` | すべてのコミットを自動署名 |
| `[core]` | `quotepath` | `false` | 日本語ファイル名をエスケープせず表示 |
| `[gpg]` | `format` | `ssh` | 署名方式に SSH を使用 |
| `[gpg "ssh"]` | `allowedsignersfile` | `~/.ssh/allowed_signers` | 署名検証用の許可済み署名者ファイル |
| `[init]` | `defaultbranch` | `main` | 新規リポジトリのデフォルトブランチ名 |
| `[pull]` | `rebase` | `true` | pull 時にマージではなくリベース |
| `[rebase]` | `autosquash` | `true` | `fixup!` / `squash!` コミットを自動整理 |

## 認証ヘルパー

`gh auth setup-git` 相当の設定として、GitHub と Gist の credential helper に `gh auth git-credential` を使います。
`gh` は絶対パスではなく `PATH` から解決するため、インストール先に依存しません。

| 対象 | helper |
|------|--------|
| `https://github.com` | `!gh auth git-credential` |
| `https://gist.github.com` | `!gh auth git-credential` |

## グローバルに設定しないもの

以下はリポジトリローカルで `gh-config-dir.zsh` が自動設定するため、グローバルには記述しない:

- `user.name`
- `user.email`
- `user.signingkey`

詳細は [Git ID の自動切り替え](../guides/04-git-identity.md) を参照。
