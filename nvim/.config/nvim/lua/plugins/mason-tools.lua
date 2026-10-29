-- Consolidated Mason tool installation
-- All ensure_installed tools in one place for easier management
return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- TypeScript/JavaScript
        "typescript-language-server",
        "eslint-lsp",
        "eslint_d",
        "prettier",
        "prettierd",
        "js-debug-adapter",

        -- Python
        "pyright",
        "ruff",
        "mypy",
        "debugpy",

        -- Go
        "gopls",
        "goimports",
        "gofumpt",
        "golangci-lint",
        "delve",
        "gomodifytags",
        "impl",

        -- Lua
        "lua-language-server",
        "stylua",

        -- YAML/Docker/DevOps
        "yaml-language-server",
        "yamllint",
        "dockerfile-language-server",
        "docker-compose-language-service",
        "hadolint",

        -- Markdown
        "markdown-toc",

        -- Shell
        "shellcheck",
        "shfmt",
      },
    },
  },
}
