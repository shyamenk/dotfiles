return {
	"MeanderingProgrammer/markdown.nvim",
	main = "render-markdown",
	opts = {},
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("render-markdown").setup({
			bullet = {
				enabled = true,
				icons = { "●", "○", "◇", "◎", "◈" },
				left_pad = 0,
				right_pad = 1,
				highlight = "RenderMarkdownBullet",
			},
			checkbox = {
				enabled = true,
				position = "inline",
				unchecked = {
					icon = "󰄱 ",
					highlight = "RenderMarkdownUnchecked",
					scope_highlight = nil,
				},

				checked = {
					icon = "✔ ",
					highlight = "RenderMarkdownChecked",
					scope_highlight = "@markup.strikethrough",
				},
				custom = {
					idea = { raw = "[!]", rendered = " ", highlight = "RenderMarkdownTodo" },
					important = { raw = "[~]", rendered = " ", highlight = "DiagnosticWarn" },
					bug = { raw = "[>]", rendered = "󰃤 ", highlight = "DiagnosticError" },
				},
			},
		})
	end,
}
