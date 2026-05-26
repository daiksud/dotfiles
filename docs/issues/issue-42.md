# Issue 42: allowed_signers を複数アカウント保持に変更

## 日付

2026-05-26

## 背景・目的

`sync_signing_key_from_gh` の初期実装では `~/.ssh/allowed_signers` を毎回1行で上書きしていたため、アカウント切り替えのたびに過去の signer エントリが消えていた。

複数アカウント運用でローカル署名検証を安定させるため、現在のアカウント行のみ更新し、他アカウントの行は保持する方式に変更する。

## 変更内容

- `dotfiles/.zsh/gh-config-dir.zsh`
  - `allowed_signers` 更新処理を「全体上書き」から「email 単位 upsert」に変更
  - 既存ファイルから同一 email 行のみ除去して新しい行を追加するロジックに変更
  - 他 email の signer 行は保持されるようにした

## 備考

- 行の一意性は email（先頭フィールド）単位で扱う。
- 同じ email で鍵が変わった場合は最新行に置換される。
