return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"jose-elias-alvarez/null-ls.nvim", -- Add null-ls for formatting
	},
	config = function()
		local mason = require("mason")
		local mason_lspconfig = require("mason-lspconfig")
		local mason_tool_installer = require("mason-tool-installer")
		local null_ls = require("null-ls")

		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})
		null_ls.setup({
			sources = {
				-- Python formatters
				null_ls.builtins.formatting.black,
				-- null_ls.builtins.formatting.autopep8, -- Uncomment if you prefer autopep8
				null_ls.builtins.formatting.isort, -- For sorting imports

				-- Linters
				null_ls.builtins.diagnostics.flake8,

				-- Your existing formatters
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.formatting.stylua,
			},
		})
		mason_lspconfig.setup({
			ensure_installed = {
				"html",
				"cssls",
				"tailwindcss",
				"lua_ls",
				"graphql",
				"emmet_ls",
				"prismals",
				"pyright",
			},
		})
		mason_tool_installer.setup({
			ensure_installed = {
				"prettier",
				"stylua",
				"eslint_d",
				"eslint",
				"black",
				"autopep8",
				"isort",
			},
		})
	end,
}
