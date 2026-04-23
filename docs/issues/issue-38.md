# Issue 38: リポジトリごとに gh ユーザーへ git identity を自動同期

## 日付

2026-04-23

## 背景・目的

リポジトリごとに利用する GitHub ユーザーを自動的に切り替え、誤ったユーザーのまま
コミット・プッシュ関連操作を行ってしまう事故を防ぐ。  
`gh auth` のアクティブユーザーに合わせて `git config user.name` / `user.email` を repo-local に同期する。

## 変更内容

- `dotfiles/.zsh/gh-config-dir.zsh` を新規作成
  - `set_gh_config_dir` 関数を実装
  - `git rev-parse --path-format=absolute --git-path gh` で Git 管理領域の `gh` パスを解決
  - Git リポジトリ内では `GH_CONFIG_DIR` を設定し、必要ならディレクトリを作成
  - Git リポジトリ外では `GH_CONFIG_DIR` を `unset`
  - `add-zsh-hook chpwd` でディレクトリ移動時に再評価
  - シェル起動時にも即時評価して初期ディレクトリに反映
  - `sync_git_identity_from_gh` を追加し、GitHub リポジトリで `gh` の認証ユーザーから `git config --local user.name/user.email` を自動更新
  - `user.name` は `gh api user` の `name`（profile name）を使用
  - `user.email` は `gh api user/emails` の primary（verified 優先）を最優先で使用し、取得不能時は公開プロフィールメールを使用
  - `user.name` と `user.email` がともにローカル設定済みの場合は、既存設定を尊重して更新しない
  - メールが取得できない場合は既存 `user.email` を維持（上書きしない）
  - ローカル `user.email` 未設定かつメール解決不能の場合は、原因に応じた英語 warning（非公開/未設定 or `user:email` scope 不足）を標準出力に表示
  - `user.name` / `user.email` を更新した場合は、設定内容を英語メッセージで標準出力に表示
  - `gh` 未ログイン時は、同期不能であることを英語メッセージで標準出力に表示
- `dotfiles/.zshrc`
  - GH 関連ロジックを本体から削除
  - 既存の `~/.zsh/*.zsh` 読み込み経由で `gh-config-dir.zsh` を読み込む構成に整理
- `dotfiles/.gitconfig`
  - 設定キーの表記を正規化（同値のまま並びとキー表記を同期）

## 備考

各リポジトリで `gh auth login` を実行すると、認証情報はそのリポジトリの `.git/gh` 配下に保存される。
これによりリポジトリ間で `gh` の認証状態が分離され、ローカル Git identity も `gh` ユーザーに追従する。
