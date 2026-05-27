# Zsh カスタムプラグイン

`dotfiles/zsh/` に配置されたカスタムプラグインの詳細リファレンスです。

## 一覧

| ファイル | エイリアス | キーバインド | 説明 |
|---------|-----------|-------------|------|
| `gh-config-dir.zsh` | — | — | Git identity + GH_CONFIG_DIR 自動設定 |
| `go-to-ghq-repository.zsh` | `ggr` | `C-]` | リポジトリ選択して `cd` |
| `edit-ghq-repository.zsh` | `egr` | — | リポジトリ選択して nvim で開く |
| `edit-selected-file.zsh` | `esf` | — | ファイル選択して nvim で開く |
| `fzf-select-history.zsh` | — | `C-r` | fzf で履歴検索 |
| `browse-github-notifications.zsh` | `bgn` | — | GitHub 通知を閲覧 |
| `open-lazygit.zsh` | `olg` | — | lazygit を起動 |
| `run-selected-command.zsh` | — | — | コマンド実行ユーティリティ |
| `history-substring-search.zsh` | — | `↑` / `↓` | サブストリング履歴検索 |
| `zshaddhistory.zsh` | — | — | 失敗コマンドを履歴から除外 |

---

## gh-config-dir.zsh

リポジトリごとに GitHub アカウント情報と SSH 署名鍵を自動設定する最重要プラグイン。

### 動作

`chpwd` フックで `cd` のたびに自動実行:

1. Git リポジトリ内かつ GitHub origin であることを確認
2. `.git/gh/` を作成し `GH_CONFIG_DIR` に設定（`gh` の認証を分離）
3. ローカルに `user.name` / `user.email` が未設定なら `gh api` で取得して設定
4. `~/.ssh/<login>.pub` を `user.signingkey` に設定
5. `~/.ssh/allowed_signers` を更新

### 提供する関数

| 関数 | 説明 |
|------|------|
| `is_github_origin_repo` | origin が github.com か判定 |
| `resolve_gh_identity` | `gh api` からログイン名・名前・メールを取得 |
| `sync_signing_key_from_gh` | SSH 署名鍵と allowed_signers を設定 |
| `sync_git_identity_from_gh` | user.name / user.email / signing key をまとめて同期 |
| `set_gh_config_dir` | GH_CONFIG_DIR を設定し identity 同期を呼び出す |

詳細は [Git ID の自動切り替え](../../guides/04-git-identity.md) を参照。

---

## go-to-ghq-repository.zsh

`gh q list` でリポジトリ一覧を取得し、fzf で選択して `cd` する。

### 動作

1. `gh q list` でローカルリポジトリのパス一覧を取得
2. `github.com` プレフィックスを除去して表示
3. fzf で選択されたパスに `cd`

### キーバインド

- `C-]` — ZLE ウィジェットとして呼び出し

### エイリアス

- `ggr`

---

## edit-ghq-repository.zsh

`gh q nvim` でリポジトリを選択して Neovim で開く。

### 動作

`run-selected-command` を経由して `gh q nvim` を実行する。

### エイリアス

- `egr`

---

## edit-selected-file.zsh

カレントディレクトリ配下のファイルを fzf で選択して Neovim で開く。

### 動作

1. `fzf` でファイルを選択
2. `run-selected-command` を経由して `nvim <file>` を実行

### エイリアス

- `esf`

---

## fzf-select-history.zsh

fzf を使ったインタラクティブ履歴検索。

### 動作

1. `history -n -r 1` で全履歴を新しい順に取得
2. 現在のコマンドライン（`$LBUFFER`）をクエリとして fzf に渡す
3. 選択された履歴をコマンドラインにセット

### キーバインド

- `C-r` — ZLE ウィジェットとして呼び出し

---

## browse-github-notifications.zsh

未読の GitHub 通知（Issue / PR）を一覧表示し、選択して詳細を開く。

### 動作

1. `gh api notifications` で未読通知を取得（全ページ）
2. Issue / PR のみをフィルタしてテーブル表示（リポジトリ#番号 / タイトル / 理由）
3. fzf で選択し、`gh pr view` または `gh issue view` を実行

### 依存

`gh`, `jq`, `fzf`, `column`

### エイリアス

- `bgn`

---

## open-lazygit.zsh

lazygit を起動し、終了時にカレントディレクトリを lazygit 内で移動した先に同期する。

### 動作

1. `LAZYGIT_NEW_DIR_FILE` を設定して lazygit を起動
2. lazygit 終了後、ファイルに書かれたディレクトリに `cd`

### エイリアス

- `olg`

---

## run-selected-command.zsh

他のプラグインから呼ばれるユーティリティ関数。

### 動作

- ZLE コンテキスト（`$WIDGET` が設定されている）: コマンドをバッファにセットして `accept-line`
- 通常コンテキスト: 履歴に追加してから直接実行

### インターフェース

```zsh
run-selected-command "command_line_string" cmd arg1 arg2 ...
```

---

## history-substring-search.zsh

`zsh-history-substring-search` プラグインのキーバインド設定。

### キーバインド

| キー | 動作 |
|------|------|
| `↑` (`^[[A`) | 入力中の文字列で上方向に履歴検索 |
| `↓` (`^[[B`) | 入力中の文字列で下方向に履歴検索 |

---

## zshaddhistory.zsh

直前のコマンドが失敗（終了コード ≠ 0）した場合に履歴への記録をスキップする。

### 動作

`zshaddhistory` フック関数を定義し、`$?` が 0 でなければ `false` を返す（= 履歴に追加しない）。
