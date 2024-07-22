return {

	"goolord/alpha-nvim",
	event = "VimEnter",
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		dashboard.section.header.val = {
			"                                                     ",
			"  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
			"  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
			"  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
			"  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
			"  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
			"  ╚═╝  ╚═══╝╚══════╝ ╚═════w   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
			"                                                     ",
			"                                                     ",
		}
		dashboard.section.buttons.val = {
			dashboard.button("ee", "  > [T]oggle File Explorer", "<cmd>NvimTreeToggle<CR>"),
			dashboard.button("ff", "󰦅  > [F]ind File", "<cmd>Telescope find_files<CR>"),
			dashboard.button("fo", "  > [F]ind Recent File", "<cmd>Telescope oldfiles<CR>"),
			dashboard.button("fs", "  > [F]Find String", "<cmd>Telescope live_grep<CR>"),
			dashboard.button("wr", "󰁯  > [R]estore Session", "<cmd>SessionRestore<CR>"),
			dashboard.button("q", "󰈆  > [Q]uit ", "<cmd>qa<CR>"),
		}
		alpha.setup(dashboard.opts)

		vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
	end,
}
