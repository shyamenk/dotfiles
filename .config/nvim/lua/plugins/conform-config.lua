return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- Markdown formatting
        markdown = { "prettier", "markdownlint" },
        -- Make sure other languages still work
        lua = { "stylua" },
        typescript = { "prettier" },
        javascript = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
      formatters = {
        -- Custom markdown formatter settings
        markdownlint = {
          args = { "--fix", "--stdin" },
        },
        prettier = {
          args = {
            "--stdin-filepath",
            "$FILENAME",
            "--prose-wrap",
            "preserve",
            "--print-width",
            "80",
          },
        },
      },
    },
  },
}