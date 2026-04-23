return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      format_on_save = {
        timeout_ms = 5000,
        lsp_fallback = true,
      },
      formatters_by_ft = {
        markdown = { "markdownlint-cli2", "markdown-toc" },
        ["markdown.mdx"] = { "markdownlint-cli2", "markdown-toc" },
      },
    },
  },
}
