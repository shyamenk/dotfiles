return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"folke/noice.nvim",
		"yavorski/lualine-macro-recording.nvim",
		-- "MunifTanjim/nui.nvim",
		"rcarriga/nvim-notify",
	},
	config = function()
		local lualine = require("lualine")

		local colors = {
			blue = "#89b4fa",
			green = "#a6e3a1",
			violet = "#cba6f7",
			yellow = "#f9e2af",
			red = "#f38ba8",
			fg = "#cdd6f4",
			bg = "#313244",
			inactive_bg = "#313244",
			seperator = "#45475a",
		}

		local lualine_theme = {
			normal = {
				a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
				b = { bg = colors.seperator, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			insert = {
				a = { bg = colors.green, fg = colors.bg, gui = "bold" },
				b = { bg = colors.seperator, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			visual = {
				a = { bg = colors.violet, fg = colors.bg, gui = "bold" },
				b = { bg = colors.seperator, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			command = {
				a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
				b = { bg = colors.seperator, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			replace = {
				a = { bg = colors.red, fg = colors.bg, gui = "bold" },
				b = { bg = colors.seperator, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			inactive = {
				a = { bg = colors.inactive_bg, fg = colors.semilightgray, gui = "bold" },
				b = { bg = colors.seperator, fg = colors.semilightgray },
				c = { bg = colors.inactive_bg, fg = colors.semilightgray },
			},
		}

		lualine.setup({
			options = {
				theme = lualine_theme,
				icons_enabled = true,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_x = {
					"filetype",
				},
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = {
					"macro_recording",
					"%S",
					{
						"filename",
						path = 1,
						symbols = {
							modified = " ●",
							readonly = " ",
							unnamed = "[No Name]",
						},
					},
				},
			},
		})
	end,
}
