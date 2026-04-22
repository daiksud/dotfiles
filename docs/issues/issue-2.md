# Issue 2: Oh-My-Zsh から Sheldon + Starship への移行

## 経緯

Oh-My-Zsh はプラグイン・テーマ・補完を一括提供するフレームワークだが、
使わない機能も含めてフレームワーク全体をロードするため、シェルの起動速度が遅くなりがちだった。
また、プラグイン管理が Oh-My-Zsh のディレクトリ構造に依存しており、
必要なプラグインだけを宣言的に管理するのが難しいという問題があった。

そこで、プラグインマネージャを **Sheldon**、プロンプトを **Starship** に分離し、
それぞれの責務を明確にした軽量な構成に移行した。

## 移行前の構成

```zsh
# .zshrc (Oh-My-Zsh)
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="bira"
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7
plugins=(brew gh git mise)
source $ZSH/oh-my-zsh.sh
```

- フレームワーク: Oh-My-Zsh
- テーマ: bira
- プラグイン: brew, gh, git, mise（Oh-My-Zsh 組み込み）
- インストール: `scripts/100-ohmyzsh.sh`（curl でインストール or `omz update`）

## 移行後の構成

### プラグインマネージャ: Sheldon

`~/.config/sheldon/plugins.toml` に TOML 形式でプラグインを宣言的に管理。

```toml
shell = "zsh"

[templates]
fpath = "fpath=(\"{{ dir }}\" $fpath)"

[plugins.fzf-tab]
github = "Aloxaf/fzf-tab"

[plugins.ohmyzsh-git]
github = "ohmyzsh/ohmyzsh"
dir = "plugins/git"

[plugins.zsh-completions]
github = "zsh-users/zsh-completions"
dir = "src"
apply = ["fpath"]

[plugins.zsh-autosuggestions]
github = "zsh-users/zsh-autosuggestions"

[plugins.zsh-autopair]
github = "hlissner/zsh-autopair"

[plugins.fast-syntax-highlighting]
github = "zdharma-continuum/fast-syntax-highlighting"

[plugins.zsh-history-substring-search]
github = "zsh-users/zsh-history-substring-search"
```

### プロンプト: Starship

`~/.config/starship.toml` でプロンプトを設定。Rust 製で高速。
Powerline 風のカスタムフォーマットを使用し、ディレクトリ・git ブランチ・言語バージョン・時刻を表示。

### .zshrc

```zsh
# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Completion system (must be before sheldon so plugins can use compdef)
autoload -Uz compinit
compinit

# Sheldon plugin manager
eval "$(sheldon source)"

# Starship prompt
eval "$(starship init zsh)"
```

### インストールスクリプト

`scripts/100-sheldon.sh` で Homebrew 経由で sheldon と starship をインストールし、`sheldon lock` でプラグインをダウンロード。

## 変更ファイル一覧

| ファイル | 変更 |
|---|---|
| `dotfiles/.config/sheldon/plugins.toml` | 新規作成 — プラグイン定義 |
| `dotfiles/.config/starship.toml` | 新規作成 — プロンプト設定 |
| `dotfiles/.zshrc` | Oh-My-Zsh → Sheldon + Starship に書き換え |
| `scripts/100-ohmyzsh.sh` | 削除 |
| `scripts/100-sheldon.sh` | 新規作成 — インストールスクリプト |

## この移行が良い理由

### 1. シェル起動速度の改善

Oh-My-Zsh はフレームワーク全体（lib/*.zsh）をロードするため、使わない機能の分だけオーバーヘッドがある。
Sheldon は指定したプラグインのみをロードし、ロック機構（`sheldon lock`）によりプラグインの解決が高速。

### 2. 宣言的なプラグイン管理

`plugins.toml` に GitHub リポジトリとディレクトリを指定するだけで、
任意のプラグインを Oh-My-Zsh に依存せず導入できる。
Oh-My-Zsh の git プラグインも `ohmyzsh/ohmyzsh` リポジトリの `plugins/git` ディレクトリを直接参照する形で継続利用。

### 3. プロンプトの独立性

Oh-My-Zsh ではテーマがフレームワーク内部の関数に依存していたが、
Starship は独立したバイナリで、zsh 以外のシェル（bash, fish, nushell）でも同じプロンプトを使える。
設定ファイルも TOML で見通しが良い。

### 4. brew, gh, mise プラグインの除外

Oh-My-Zsh の `brew`, `gh`, `mise` プラグインは主に補完定義を提供するものだが、
これらのツールは自前で `eval "$(brew shellenv)"` や `eval "$(mise activate zsh)"` 等のシェル統合を持つため、
Oh-My-Zsh プラグインとしてロードする必要がない。`zsh-completions` で汎用的な補完を補っている。

## 注意点: compinit の読み込み順序

移行当初は `sheldon source` の後に `compinit` を呼んでいたが、
fzf-tab 等のプラグインが `compdef` を使用するため、`compinit` を先に呼ぶ必要があった。
これは `996bb3d` で修正済み。

```zsh
# ✅ 正しい順序
autoload -Uz compinit
compinit
eval "$(sheldon source)"  # プラグインが compdef を使えるようになる
```
