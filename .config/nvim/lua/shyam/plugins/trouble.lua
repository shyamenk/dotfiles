return {
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons", "folke/todo-comments.nvim" },
	opts = {
		focus = true,
	},
	cmd = "Trouble",
	keys = {
		{ "<leader>xw", "<cmd>Trouble diagnostics toggle<CR>", desc = "Toggle Trouble Diagnostics" },
		{
			"<leader>xd",
			"<cmd>Trouble diagnostics toggle filter.buf=0<CR>",
			desc = "Toggle Trouble Diagnostics for current buffer",
		},
		{ "<leader>xq", "<cmd>Trouble quickfix toggle<CR>", desc = "Toggle Trouble Quickfix" },
		{ "<leader>xl", "<cmd>Trouble loclist toggle<CR>", desc = "Open Trouble Location List" },
		{ "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "Open Trouble TODO List" },
	},
}
