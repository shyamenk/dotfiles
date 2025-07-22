return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },

		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "+" },
					change = { text = "~" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
				},
			})
			vim.keymap.set("n", "<leader>gh", ":Gitsigns preview_hunk<CR>", { desc = "Git Preview Hunk" })
			vim.keymap.set(
				"n",
				"<leader>gt",
				":Gitsigns toggle_current_line_blame<CR>",
				{ desc = "Git Toggle Current Line Blame" }
			)
		end,
	},
}
