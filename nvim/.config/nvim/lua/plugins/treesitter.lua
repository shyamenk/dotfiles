-- Consolidated Treesitter configuration
-- All parsers in one place for easier management
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- Core
        "lua",
        "vim",
        "vimdoc",
        "query",
        "regex",

        -- Web development
        "typescript",
        "tsx",
        "javascript",
        "jsdoc",
        "html",
        "css",

        -- Data formats
        "json",
        "jsonc",
        "yaml",
        "toml",

        -- Markdown
        "markdown",
        "markdown_inline",

        -- Python
        "python",

        -- Shell
        "bash",

        -- Docker
        "dockerfile",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { "markdown" },
      },
    },
  },
}
