return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      format_on_save = {
        timeout_ms = 5000,
        lsp_fallback = true,
      },
      formatters = {
        ["markdownlint-cli2"] = {
          args = { "--config", vim.fn.expand("~/.markdownlint-cli2.cjs"), "--fix", "$FILENAME" },
        },
      },
      formatters_by_ft = {
        markdown = { "markdownlint-cli2", "markdown-toc" },
        ["markdown.mdx"] = { "markdownlint-cli2", "markdown-toc" },
      },
    },
  },
}
