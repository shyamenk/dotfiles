return {
	"folke/zen-mode.nvim",
	"tpope/vim-obsession",
	config = function()
		require("zen-mode").setup({
			window = {
				backdrop = 0.95,
				width = 120,
				height = 1,
				options = {
					signcolumn = "no",
					number = false,
					relativenumber = false,
				},
			},
			plugins = {
				options = {
					enabled = true,
					ruler = true,
					showcmd = false,
					laststatus = 0,
				},
				twilight = { enabled = false },
				gitsigns = { enabled = false },
				tmux = { enabled = true },
			},
		})
	end,
}
