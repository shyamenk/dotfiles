return {
	"ThePrimeagen/harpoon",

	config = function()
		local mark = require("harpoon.mark")
		local term = require("harpoon.term")
		local ui = require("harpoon.ui")

		-- General Key Binding
		vim.keymap.set("n", "<leader>a", mark.add_file, { desc = "Harpoon: Add File" })
		vim.keymap.set("n", "<C-e>", ":Telescope harpoon marks <CR>", { desc = "Harpoon: List Files" })

		vim.keymap.set("n", "<C-q>", function()
			ui.nav_next()
		end, { desc = "Harpoon: Next File" })

		vim.keymap.set("n", "<C-a>", function()
			ui.nav_prev()
		end, { desc = "Harpoon: Previous File" })

		vim.keymap.set("n", "<C-z>", function()
			term.gotoTerminal(1)
		end, { desc = "Harpoon: Terminal 1" })

		vim.keymap.set("n", "<C-x>", function()
			term.clear_all()
		end, { desc = "Harpoon: Clear All Terminals" })
	end,
}
