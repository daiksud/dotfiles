import { themes as prismThemes } from "prism-react-renderer";
import type { Config } from "@docusaurus/types";
import type * as Preset from "@docusaurus/preset-classic";
import remarkGithubAdmonitionsToDirectives from "remark-github-admonitions-to-directives";

const config: Config = {
  title: "daiksud/dotfiles",
  tagline: "macOS / Ubuntu 統一開発環境",
  trailingSlash: false,

  future: {
    v4: true,
    faster: true,
  },

  url: "https://daiksud.github.io",
  baseUrl: "/dotfiles/",

  organizationName: "daiksud",
  projectName: "dotfiles",

  onBrokenLinks: "throw",

  i18n: {
    defaultLocale: "ja",
    locales: ["ja"],
  },

  presets: [
    [
      "classic",
      {
        docs: {
          path: "../docs/",
          routeBasePath: "/",
          sidebarPath: "./sidebars.ts",
          editUrl: "https://github.dev/daiksud/dotfiles/tree/main/.docusaurus/",
          beforeDefaultRemarkPlugins: [remarkGithubAdmonitionsToDirectives],
        },
        blog: false,
        theme: {
          customCss: "./src/css/custom.css",
        },
      } satisfies Preset.Options,
    ],
  ],

  themes: ["@docusaurus/theme-mermaid"],

  plugins: ["./plugins/pagefind-plugin.ts"],

  markdown: {
    format: "detect",
    mermaid: true,
  },

  themeConfig: {
    colorMode: {
      defaultMode: "dark",
    },
    docs: {
      sidebar: {
        hideable: true,
        autoCollapseCategories: true,
      },
    },
    navbar: {
      title: "daiksud/dotfiles",
      items: [
        {
          type: "docSidebar",
          sidebarId: "guidesSidebar",
          position: "left",
          label: "📖 ガイド",
        },
        {
          type: "docSidebar",
          sidebarId: "referenceSidebar",
          position: "left",
          label: "📋 リファレンス",
        },
        {
          type: "docSidebar",
          sidebarId: "developmentSidebar",
          position: "left",
          label: "🛠️ 開発",
        },
        {
          href: "https://github.com/daiksud/dotfiles",
          label: "GitHub",
          position: "right",
        },
      ],
    },
    footer: {
      style: "dark",
      copyright: `Copyright ${new Date().getFullYear()} daiksud`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ["bash", "json", "toml", "lua", "ini"],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
