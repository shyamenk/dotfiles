return {
	{
		"aaronhallaert/advanced-git-search.nvim",
		cmd = { "AdvancedGitSearch" },
		config = function()
			require("telescope").setup({
				extensions = {
					advanced_git_search = {},
				},
			})

			require("telescope").load_extension("advanced_git_search")
			vim.keymap.set("n", "<leader>ga", ":AdvancedGitSearch<CR>", { desc = "Advanced Git Search" })
		end,
		dependencies = {},
	},
}
