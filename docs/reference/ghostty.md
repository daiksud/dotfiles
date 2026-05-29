# Ghostty

Ghostty ターミナルエミュレータの設定ファイルリファレンスです。

## ファイル

`dotfiles/ghostty/config` → `~/.config/ghostty/config`

## 設定一覧

### 外観

| 設定                        | 値                       | 説明               |
| --------------------------- | ------------------------ | ------------------ |
| `theme`                     | `TokyoNight Storm`       | カラースキーム     |
| `font-family`               | `Moralerspace Neon HW`   | フォント           |
| `font-size`                 | `13.5`                   | フォントサイズ     |
| `background-image`          | `hololive-en-advent.jpg` | 背景画像           |
| `background-image-fit`      | `cover`                  | 画像のフィット方法 |
| `background-image-opacity`  | `0.06`                   | 背景画像の透過率   |
| `background-image-position` | `center`                 | 画像の配置         |

### ウィンドウ

| 設定                               | 値                        | 説明                                             |
| ---------------------------------- | ------------------------- | ------------------------------------------------ |
| `fullscreen`                       | `non-native-visible-menu` | フルスクリーンモード                             |
| `macos-non-native-fullscreen`      | `visible-menu`            | macOS 非ネイティブフルスクリーン                 |
| `macos-titlebar-style`             | `hidden`                  | タイトルバーを非表示                             |
| `window-inherit-working-directory` | `false`                   | 新ウィンドウでカレントディレクトリを引き継がない |
| `window-padding-y`                 | `0`                       | 垂直パディング                                   |

### 入力

| 設定                      | 値     | 説明                                 |
| ------------------------- | ------ | ------------------------------------ |
| `macos-option-as-alt`     | `true` | Option キーを Alt として使用         |
| `mouse-hide-while-typing` | `true` | タイピング中にマウスカーソルを非表示 |

### 無効化したキーバインド

tmux でタブ・ペイン管理を行うため、Ghostty 組み込みのタブ・スプリット系キーバインドをすべて無効化している。

**タブ系:**

- `⌘T` (新規タブ)
- `⌘⇧[` / `⌘⇧]` (タブ切り替え)
- `⌘1` 〜 `⌘9` (タブ番号ジャンプ)

**スプリット系:**

- `⌘D` / `⌘⇧D` (分割)
- `⌘⌥↑↓←→` (ペインリサイズ)
- `⌘⌃↑↓←→` (ペイン移動)
- `⌘⇧Enter` (ペイン追加)

## 背景画像

`dotfiles/ghostty/hololive-en-advent.jpg` が設定ディレクトリに含まれており、シンボリックリンク経由で配置される。
