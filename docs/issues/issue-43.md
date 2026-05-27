# Issue 43: dotfiles インストール方法の変更（JSON 対応表 + .config 展開）

## 日付

2026-05-27

## 背景・目的

これまで `install.sh` はシェルグロブ (`dotfiles/.*`) を走査し、ファイル名をそのまま `~/` 以下にシンボリックリンクする方式だった。この方式ではリンク先を柔軟に制御できず、`~/.config/X` のような深いパスへのリンクや任意のパス（`~/.copilot/skills` 等）への対応が困難だった。

また、`.gitconfig` に対して `user.name`/`user.email` を除外した同期処理が実装されていたが、これらの情報は `gh-config-dir.zsh` によってリポジトリごとにローカル設定されるようになったため、グローバル `.gitconfig` での特別扱いは不要になった。

## 変更内容

- **`install_map.json` 新規作成**
  - シンボリックリンクの対応表（`source → target`）を JSON で管理
  - `"zshrc": "~/.zshrc"`, `"nvim": "~/.config/nvim"` のように宛先パスを柔軟に指定可能

- **`dotfiles/` ディレクトリの再編**
  - ドット付きエントリをドットなしにリネーム（`.zsh` → `zsh`, `.zshrc` → `zshrc`, `.tmux.conf` → `tmux.conf`, `.gitconfig` → `gitconfig`）
  - `dotfiles/.config/*` を一段展開（`ghostty`, `mise`, `nvim`, `sheldon`, `starship.toml` を `dotfiles/` 直下へ移動）
  - `dotfiles/.config/` は管理対象外となるため `.gitignore` を削除し、ルート `.gitignore` に追加

- **`install.sh` の変更**
  - グロブベースのシンボリックリンクループを削除
  - `parse_links()` 関数を追加（Python3 の `json` モジュールで `install_map.json` をパース）
  - `ensure_real_parent_dir()` 関数を追加（宛先の親ディレクトリがシンボリックリンクの場合に実ディレクトリへ変換し内容を移行）
  - `gitconfig` の特別処理（`is_excluded_gitconfig_key`, `non_user_gitconfig_snapshot`, `has_non_user_gitconfig_diff`, `sync_dotfiles_gitconfig_from_home` 関数および copy/sync ブロック）を全廃
  - `gitconfig` は通常エントリとして `install_map.json` に含め `~/.gitconfig` にシンボリックリンク

## 備考

- `~/.config` が旧方式で `dotfiles/.config` へのシンボリックリンクになっている環境では、`install.sh` 実行時に `ensure_real_parent_dir()` が自動で実ディレクトリへ変換し、未追跡コンテンツ（`gh/`, `github-copilot/` 等）を移行する
- `nvim.bak` は `install_map.json` に含めず追跡対象外とした
- `.devcontainer/Dockerfile` の `COPY` パスも `dotfiles/.config/mise` → `dotfiles/mise` に更新
- 新たにリンク先を追加する場合は `install_map.json` にエントリを追記するだけでよい
