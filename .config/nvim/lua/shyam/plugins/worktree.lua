return {
	"ThePrimeagen/git-worktree.nvim",
	config = function()
		require("git-worktree").setup()
		require("telescope").load_extension("git_worktree")
		vim.keymap.set("n", "<leader>gws", ":Telescope git_worktree git_worktrees<CR>", { desc = "Git Worktrees" })
		vim.keymap.set(
			"n",
			"<leader>gwc",
			":lua require('telescope').extensions.git_worktree.create_git_worktree() <CR>",
			{ desc = "Create Git Worktree" }
		)
	end,
}
