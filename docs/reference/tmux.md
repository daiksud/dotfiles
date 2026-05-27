# tmux

ターミナルマルチプレクサ（tmux）の設定リファレンスです。

## ファイル

`dotfiles/tmux.conf` → `~/.tmux.conf`

## 基本設定

| 設定 | 値 | 説明 |
|------|-----|------|
| prefix | `C-t` | プレフィックスキー（デフォルトの `C-b` を無効化） |
| `default-terminal` | `xterm-ghostty` | Ghostty の機能を tmux 内でも維持 |
| `mode-keys` | `vi` | コピーモードで vi キーバインド |

## キーバインド

### ウィンドウ・ペイン操作

| キー | 動作 |
|------|------|
| `prefix c` | 新規ウィンドウ（カレントパスを引き継ぐ） |
| `prefix \` | 水平分割（カレントパスを引き継ぐ） |
| `prefix -` | 垂直分割（カレントパスを引き継ぐ） |
| `prefix h/j/k/l` | ペイン移動（vim 風） |
| `prefix r` | 設定リロード |

### コピーモード

| キー | 動作 |
|------|------|
| `v` | 選択開始 |
| `y` | コピー＆コピーモード終了 |

### 特殊キー

| キー | 動作 |
|------|------|
| `Shift+Enter` | `\e[13;2u` を送信（kitty keyboard protocol） |

## プラグイン

TPM (Tmux Plugin Manager) で管理。プラグインディレクトリ: `~/.tmux/plugins/`

| プラグイン | 説明 |
|-----------|------|
| `tmux-plugins/tpm` | プラグインマネージャ本体 |
| `tmux-plugins/tmux-sensible` | 基本的なベストプラクティス設定 |
| `janoamaral/tokyo-night-tmux` | Tokyo Night テーマ |

### Tokyo Night 設定

| キー | 値 | 説明 |
|------|-----|------|
| `@tokyo-night-tmux_theme` | `storm` | Storm バリアント |

## 自動起動

`.zshrc` で tmux セッションに自動接続する:

```zsh
if [[ -z "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s main
fi
```

- `new-session -A -s main` — `main` セッションが存在すれば attach、なければ作成
- `exec` — シェルを tmux に置き換え（tmux 終了時にターミナルが閉じる）

## TPM の初期化

Homebrew のパスをプリペンドして TPM を起動:

```
run 'PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH" ~/.tmux/plugins/tpm/tpm'
```

これにより TPM のプラグインスクリプトが Homebrew の bash 5+ を使用できる。
