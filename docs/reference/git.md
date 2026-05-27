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

## グローバルに設定しないもの

以下はリポジトリローカルで `gh-config-dir.zsh` が自動設定するため、グローバルには記述しない:

- `user.name`
- `user.email`
- `user.signingkey`

詳細は [Git ID の自動切り替え](../guides/04-git-identity.md) を参照。
