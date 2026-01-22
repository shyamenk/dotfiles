-- Python development enhancements (extends LazyVim's Python extra)
return {
  -- Additional Mason tools
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "mypy", -- Static type checker
        "debugpy", -- Python debugger
      },
    },
  },

  -- Virtual environment selector
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    cmd = "VenvSelect",
    ft = "python",
    dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim" },
    opts = {
      name = { "venv", ".venv", "env", ".env" },
    },
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    },
  },
}
