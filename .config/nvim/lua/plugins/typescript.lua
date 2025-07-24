return {
  -- Configure Mason to install TypeScript tools
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- TypeScript Language Server
        "typescript-language-server",
        -- Linters
        "eslint-lsp",
        -- Formatters
        "prettier",
        "prettierd", -- Faster prettier daemon
        -- Markdown tools
        "markdownlint",
        "markdown-toc",
        -- Additional tools
        "js-debug-adapter", -- For debugging
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        tsserver = {
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "literal",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },
        eslint = {
          settings = {
            workingDirectories = { mode = "auto" },
          },
        },
      },
    },
  },

  -- Add more treesitter parsers for TypeScript development
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "typescript",
        "tsx",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
      },
    },
  },
}
