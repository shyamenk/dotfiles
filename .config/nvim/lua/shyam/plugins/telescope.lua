return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
		"nvim-telescope/telescope-symbols.nvim",
		"folke/todo-comments.nvim",
		"folke/twilight.nvim",
		"nvim-telescope/telescope-live-grep-args.nvim",
		version = "^1.0.0",
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		local focus_preview = function(prompt_bufnr)
			local action_state = require("telescope.actions.state")
			local picker = action_state.get_current_picker(prompt_bufnr)
			local prompt_win = picker.prompt_win
			local previewer = picker.previewer
			local winid = previewer.state.winid
			local bufnr = previewer.state.bufnr
			vim.keymap.set("n", "<Tab>", function()
				vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", prompt_win))
			end, { buffer = bufnr })
			vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", winid))
		end
		telescope.setup({
			defaults = {
				layout_strategy = "horizontal",
				layout_config = {
					preview_width = 0.65,
					horizontal = {
						size = {
							width = "95%",
							height = "95%",
						},
					},
				},
				path_display = { "smart" },
				pickers = {
					find_files = {
						theme = "dropdown",
					},
				},
				mappings = {
					i = {
						["<C-h>"] = "which_key",
						["<C-k>"] = actions.move_selection_previous, -- move to prev result
						["<C-j>"] = actions.move_selection_next, -- move to next result
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						["<Tab>"] = focus_preview,
					},
				},
			},
		})

		telescope.load_extension("fzf")
		telescope.load_extension("noice")
		telescope.load_extension("harpoon")
		telescope.load_extension("advanced_git_search")
		telescope.load_extension("live_grep_args")
		-- set keymaps
		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find Files" })
		vim.keymap.set(
			"n",
			"<leader>fg",
			"<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>",
			{ desc = "Live Grep Args" }
		)
		vim.keymap.set(
			"n",
			"<leader>fc",
			'<cmd>lua require("telescope.builtin").live_grep({ glob_pattern = "!{spec,test}"})<CR>',
			{ desc = "Find String With Pattern" }
		)

		vim.keymap.set("n", "<leader>sn", function()
			builtin.find_files({ cwd = vim.fn.stdpath("config") })
		end, { desc = "Find Neovim Configuration Files" })
		local keymap = vim.keymap -- for conciseness
		keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
		keymap.set("n", "<leader>fh", "<cmd>Telescope find_files hidden=true<cr>", { desc = "Find Hidden Files" })
		keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
		keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Open Recent File" })
		keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find String" })
		keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find String Under Cursor" })
		keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find Todo Comments" })
		vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps" })
	end,
}
