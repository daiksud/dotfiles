# Issue 15: 新規ターミナルが前のセッションのディレクトリで起動する問題を修正

## 日付

2026-04-15

## 背景・目的

新しく Ghostty ウィンドウを開くと、前のウィンドウのカレントディレクトリ（例: `/Users/<YOUR_USERNAME>/ghq/github.com/example-org/example-repo`）が引き継がれてしまう問題があった。

また、tmux の新規ウィンドウ (`Prefix + c`) を開くと、現在のペインのディレクトリではなくセッション作成時の CWD（`team.infra`）が常に使われてしまう問題もあった。

## 変更内容

- `dotfiles/.config/ghostty/config`: `window-inherit-working-directory = false` を追加し、新規ウィンドウが常にホームディレクトリから始まるようにした
- `dotfiles/.config/tmux/tmux.conf`: `bind c new-window -c "#{pane_current_path}"` を追加し、新規ウィンドウが現在のペインの CWD を引き継ぐようにした

## 備考

- `.zshrc` の `exec tmux new-session -A -s main` でセッションが作成された CWD が、新規ウィンドウのデフォルトパスとして使われていた
- split-window には既に `#{pane_current_path}` が設定されていたが、`new-window` には設定されていなかった
