return {
	"nvim-lua/plenary.nvim",
	"christoomey/vim-tmux-navigator",
	vim.diagnostic.config({
		signs = {
			text = {
				[vim.diagnostic.severity.ERROR] = "E",
				[vim.diagnostic.severity.WARN] = "W",
				[vim.diagnostic.severity.INFO] = "I",
				[vim.diagnostic.severity.HINT] = "H",
			},
		},
	}),
}
