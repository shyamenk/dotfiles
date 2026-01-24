return {
	"windwp/nvim-autopairs",
	event = { "InsertEnter" },
	dependencies = {
		"hrsh7th/nvim-cmp",
	},
	config = function()
		local autopairs = require("nvim-autopairs")

		autopairs.setup({
			check_ts = true, -- enable treesitter
			ts_config = {
				lua = { "string" },
				javascript = { "template_string" },
				javascriptreact = { "template_string" }, -- for JSX
				typescriptreact = { "template_string" }, -- for TSX
				java = false,
			},
		})

		-- Add JSX/TSX specific rules
		local Rule = require("nvim-autopairs.rule")
		local ts_conds = require("nvim-autopairs.ts-conds")

		-- Add spaces between parentheses
		autopairs.add_rules({
			Rule("<", ">", { "javascriptreact", "typescriptreact" }):with_pair(
				ts_conds.is_not_ts_node({ "string", "comment" })
			),
			Rule(" ", " ", { "javascriptreact", "typescriptreact" }):with_pair(function(opts)
				local pair = opts.line:sub(opts.col - 1, opts.col)
				return vim.tbl_contains({ "()", "[]", "{}" }, pair)
			end),
		})

		-- Integration with nvim-cmp
		local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		local cmp = require("cmp")
		cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
	end,
}
