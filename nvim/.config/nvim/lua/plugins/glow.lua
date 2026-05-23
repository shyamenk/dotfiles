return {
  "ellisonleao/glow.nvim",
  cmd = "Glow",
  ft = "markdown",
  config = function()
    require("glow").setup({
      border = "rounded",
      style = "dark",
      width = 120,
      height_ratio = 0.8,
    })
  end,
  keys = {
    { "<leader>mg", "<cmd>Glow<cr>", desc = "Markdown Preview (Terminal)" },
  },
}
