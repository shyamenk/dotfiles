return {
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		use_default_keymaps = true,
		config = true,
		vim.keymap.set("n", "<leader>gp", ":Neogit pull<CR>", { desc = "Git pull" }),
		vim.keymap.set("n", "<leader>gP", ":Neogit push<CR>", { desc = "Git push" }),
		vim.keymap.set("n", "<leader>gb", ":Telescope git_branches<CR>", { desc = "Git branches" }),
		vim.keymap.set("n", "<leader>gC", ":Telescope git_commits<CR>", { desc = "Git Commits" }),
		vim.keymap.set("n", "<leader>gs", ":Telescope git_status<CR>", { desc = "Git Status" }),
		vim.keymap.set("n", "<leader>gB", ":G blame<CR>", { desc = "Git blame" }),
		vim.keymap.set("n", "<leader>gc", ":Neogit commit<CR>", { desc = "Git commit" }),
		vim.keymap.set("n", "<leader>gg", ":Neogit<CR>", { desc = "Neo Git" }),
	},
}
