# .docusaurus

[Docusaurus](https://docusaurus.io/) によるドキュメントサイトを構築するためのディレクトリです。

ドキュメント本体（Markdown ファイル）はリポジトリルートの `docs/` にあります。このディレクトリには Docusaurus の設定・テーマカスタマイズ・ビルド成果物など、サイト構築に必要なコードだけを配置しています。

## ディレクトリ構成

| パス | 役割 |
| --- | --- |
| `docusaurus.config.ts` | サイト全体の設定（タイトル、URL、プラグイン、ナビバーなど） |
| `plugins/` | カスタム Docusaurus プラグイン（Pagefind 検索インデックス生成） |
| `sidebars.ts` | サイドバーの構成定義 |
| `src/components/` | カスタム MDX コンポーネント（下記参照） |
| `src/theme/` | Docusaurus テーマのオーバーライド（`MDXComponents.ts`、`SearchBar/`） |
| `src/css/custom.css` | サイト全体のカスタム CSS（Tokyo Night Storm 配色） |
| `src/pages/` | 独自ページ（React コンポーネント） |
| `static/` | 静的アセット |
| `build/` | `docs:build` の出力先（`.gitignore` 対象） |
| `package.json` | Docusaurus とプラグインの依存関係 |

## カスタムコンポーネント

`docs/` 内の MDX ファイルで使用できるコンポーネントです。`src/theme/MDXComponents.ts` でグローバル登録しています。

| コンポーネント | 用途 |
| --- | --- |
| `<Hero>` | ランディングページのヒーローセクション |
| `<HeroLeft>` / `<HeroRight>` | ヒーロー内の左右レイアウト |
| `<Terminal>` | ターミナル風のコードブロック表示（ライト/ダーク両対応） |
| `<FeatureGrid>` | 特徴一覧のグリッドレイアウト |
| `<Feature>` | グリッド内の個別特徴カード |

## サイト内検索

[Pagefind](https://pagefind.app/) によるビルド時ローカル検索を実装しています。

- `plugins/pagefind-plugin.ts` — Docusaurus の `postBuild` フックで Pagefind Node API を呼び出し、検索インデックスを生成
- `src/theme/SearchBar/` — Pagefind UI の React ラッパー。ナビバーに検索ボタンを表示し、モーダルで検索結果を表示
- キーボードショートカット: `⌘+K`（macOS）/ `Ctrl+K`（Windows/Linux）

> [!NOTE]
> 検索は `docs:build` で生成されるインデックスに依存するため、`docs:start`（開発サーバー）では動作しません。検索を確認するには `docs:build` → `docs:serve` を実行してください。

## コマンド

すべてのコマンドはリポジトリルートから実行します。

```bash
bun run docs:install   # 依存パッケージのインストール
bun run docs:start     # 開発サーバーの起動（ホットリロード対応）
bun run docs:build     # 本番用の静的サイトを生成
bun run docs:serve     # ビルド済みサイトのプレビュー
```

## なぜ `.docusaurus` ディレクトリに分離しているか

GitHub 上で `docs/` を直接閲覧する利用者にとって、Docusaurus の設定ファイルや `node_modules` が目に入らないようにするためです。ドット付きディレクトリにすることで、リポジトリルートの見通しもすっきり保てます。
