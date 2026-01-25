return {
  "ellisonleao/glow.nvim",
  cmd = "Glow",
  ft = "markdown",
  opts = {
    border = "rounded",
    style = "dark",
    width = 120,
    height_ratio = 0.8,
  },
  keys = {
    { "<leader>mg", "<cmd>Glow<cr>", desc = "Markdown Preview (Terminal)" },
  },
}
