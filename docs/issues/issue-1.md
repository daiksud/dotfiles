# Issue 1: git コミットへの SSH 署名の導入

## 経緯

GitHub は 2022 年に SSH キーをコミット署名に使用できる機能を正式サポートした。
それまでコミット署名といえば GPG キーを用いるのが一般的だったが、GPG は鍵管理が煩雑で、
初期セットアップのハードルが高いという問題があった。

開発者がすでに SSH キーを GitHub への認証に使っている場合、追加で GPG キーを作成・管理する
必要性は薄い。そこで、既存の `~/.ssh/id_ed25519` を署名にも流用し、コミットの真正性を
担保する設定を `dotfiles/.gitconfig` に追加した。

## 変更内容

### `dotfiles/.gitconfig`

```ini
[user]
  signingKey         = ~/.ssh/id_ed25519.pub

[commit]
  gpgsign            = true

[gpg]
  format             = ssh

[gpg "ssh"]
  allowedSignersFile = ~/.ssh/allowed_signers
```

| 設定キー | 値 | 目的 |
|---|---|---|
| `user.signingKey` | `~/.ssh/id_ed25519.pub` | 署名に使用する公開鍵のパス |
| `commit.gpgsign` | `true` | すべてのコミットを自動署名 |
| `gpg.format` | `ssh` | GPG ではなく SSH 署名方式を使用 |
| `gpg.ssh.allowedSignersFile` | `~/.ssh/allowed_signers` | 署名検証時に参照する許可済み署名者ファイル |

### `install.sh`

`~/.ssh/allowed_signers` を自動生成するステップを追加。
`git log --show-signature` や `git verify-commit` で署名を検証する際に必要となるファイルで、
フォーマットは `<email> <keytype> <pubkey>` の1行。

## この変更が良い理由

### 1. SSH キーの再利用でセットアップコストがゼロに近い

GPG 署名を導入する場合、鍵の生成・エクスポート・GitHub への登録・有効期限管理が必要になる。
一方 SSH 署名は、GitHub への認証に使っている既存キーをそのまま流用できるため、
追加の鍵管理が不要。

### 2. ed25519 キーのセキュリティ強度

`id_ed25519` は楕円曲線 EdDSA (Edwards-curve Digital Signature Algorithm) を使った鍵で、
RSA-4096 と同等以上のセキュリティを持ちつつ、鍵長が短く処理も高速。
署名用途としても適切な強度を持つ。

### 3. `gpgsign = true` による一貫した署名

手動で `-S` フラグを付け忘れるリスクをなくし、すべてのコミットに自動で署名が付く。
GitHub 上で「Verified」バッジが表示されるようになり、コミットの改ざん検知が容易になる。

### 4. GPG 依存を排除

macOS 環境では GPG の導入に `gpg` コマンドや `pinentry` 等の追加インストールが必要だが、
SSH 署名は標準の `ssh-keygen` のみで完結する。dotfiles の依存関係をシンプルに保てる。

## 補足: GitHub への署名キー登録

この設定を有効にするには、GitHub 側に SSH 署名キーを登録する必要がある。
認証キーと署名キーは別々に登録できる（同じ公開鍵を両方に登録してもよい）。

1. [Settings → SSH and GPG keys](https://github.com/settings/keys) を開く
2. **New signing key** をクリック
3. `~/.ssh/id_ed25519.pub` の内容を貼り付けて保存

登録後、GitHub 上のコミットに「Verified」バッジが表示される。
