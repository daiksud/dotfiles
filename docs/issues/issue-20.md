# Issue 20: zsh カスタム関数の命名統一と GitHub 通知ビューアの追加

## 日付

2026-04-15

## 背景・目的

`gh api notifications` で取得した未読通知のうち Issue / Pull Request を一覧し、`fzf` で `repo_name#issue_number`, `title`, `reason` を見ながら選択して、そのまま `gh issue view` または `gh pr view` で内容を開けるようにする。あわせて、既存の zsh カスタム関数について命名規則とファイル名を統一し、短縮名も新しいフルネームに対応した alias へ揃える。

## 変更内容

- `dotfiles/.zsh/browse-github-notifications.zsh`
  - `browse-github-notifications` 関数を追加
  - `gh api notifications` で未読通知を取得し、Issue / Pull Request だけを抽出
  - 通知 API に含まれる番号・タイトル・reason を使い、`fzf` の選択一覧に `repo_name#issue_number`, `title`, `reason` を表示
  - `column` を使って fzf の表示列幅を揃え、ヘッダーと各行が見やすく並ぶようにした
  - 遅延要因だった GraphQL の participants 取得をやめて、一覧表示を軽くした
  - 選択後に通知種別に応じて `gh issue view` または `gh pr view` のコマンドを組み立て、widget 実行時は ZLE のバッファに入れてそのまま実行、通常実行時はヒストリに積んでから実行するようにした
  - 略称 alias を `bgn` に統一した
- `dotfiles/.zsh/go-to-ghq-repository.zsh`
  - `cdg` を `go-to-ghq-repository` にリネームし、略称 alias は `ggr` に変更
  - bindkey 用に `zle -N` を明示し、キーバインドと関数名を一致させた
- `dotfiles/.zsh/edit-ghq-repository.zsh`
  - `ng` を `edit-ghq-repository` にリネームし、略称 alias は `egr` に変更
  - 選択したリポジトリから `nvim ...` コマンドを組み立て、widget 実行時は ZLE のバッファに入れてそのまま実行、通常実行時はヒストリに積んでから実行するようにした
  - 選択キャンセル時に ghq root を誤って開かないように、選択結果とルート結合の処理を分離した
- `dotfiles/.zsh/edit-selected-file.zsh`
  - `fn` を `edit-selected-file` にリネームし、略称 alias は `esf` に変更
  - 選択したファイルから `nvim ...` コマンドを組み立て、widget 実行時は ZLE のバッファに入れてそのまま実行、通常実行時はヒストリに積んでから実行するようにした
- `dotfiles/.zsh/run-selected-command.zsh`
  - 選択済みコマンドを ZLE バッファに流すか、ヒストリに積んでから通常実行するかを共通化する helper を追加
- `dotfiles/.zsh/open-lazygit.zsh`
  - `lg` を `open-lazygit` にリネームし、略称 alias は `olg` に変更
- `docs/issues/issue-20.md`
  - 今回の変更内容を記録

## 備考

fzf には整形済みの表示列だけを見せ、元データは別列で保持することで、列揃えと選択後の `gh issue view` / `gh pr view` の分岐を両立している。`edit-*` 系と `browse-github-notifications` は widget と通常関数の両方で使えるようにし、widget 時は `BUFFER` + `accept-line`、通常時は `print -s` で履歴へ積んでから実行するようにした。`fzf-select-history` のように既に命名規則に沿っているものは維持し、`zshaddhistory` は zsh のフック名が固定されているため例外としてそのままにしている。
