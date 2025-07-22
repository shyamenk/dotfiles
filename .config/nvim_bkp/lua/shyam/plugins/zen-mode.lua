return {
	"folke/zen-mode.nvim",
	"tpope/vim-obsession",
	config = function()
		require("zen-mode").setup({
			vim.keymap.set("n", "<leader>gz", "<cmd>ZenMode<cr>", { desc = "Toggle Zen Mode" }),
			-- window = {
			-- 	backdrop = 0.95,
			-- 	width = 120,
			-- 	height = 1,
			-- 	options = {
			-- 		signcolumn = "no",
			-- 		number = false,
			-- 		relativenumber = false,
			-- 	},
			-- },
			options = {},
			plugins = {
				-- 	options = {
				-- 		enabled = true,
				-- 		ruler = true,
				-- 		showcmd = false,
				-- 		laststatus = 0,
				-- 	},
				-- 	twilight = { enabled = false },
				-- 	gitsigns = { enabled = false },
				tmux = { enabled = false },
				-- 	alacritty = {
				-- 		enabled = true,
				-- 		font = "18", -- font size
				-- 	},
			},
		})
	end,
}
