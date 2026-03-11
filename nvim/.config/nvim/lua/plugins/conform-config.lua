return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- Markdown formatting
        markdown = { "prettier" },
        -- Make sure other languages still work
        lua = { "stylua" },
        typescript = { "prettier" },
        javascript = { "prettier" },
        typescriptreact = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        -- Python formatting
        python = { "ruff_format" },
      },
      formatters = {
        -- Custom markdown formatter settings
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