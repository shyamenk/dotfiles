return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		local lspconfig = require("lspconfig")
		local mason_lspconfig = require("mason-lspconfig")
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local keymap = vim.keymap

		-- Set up LSP keybindings when a language server attaches
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }

				-- Navigation
				keymap.set(
					"n",
					"gR",
					"<cmd>Telescope lsp_references<CR>",
					{ buffer = ev.buf, desc = "Show LSP references" }
				)
				keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = ev.buf, desc = "Go to declaration" })
				keymap.set(
					"n",
					"gd",
					"<cmd>Telescope lsp_definitions<CR>",
					{ buffer = ev.buf, desc = "Show LSP definitions" }
				)
				keymap.set(
					"n",
					"gi",
					"<cmd>Telescope lsp_implementations<CR>",
					{ buffer = ev.buf, desc = "Show LSP implementations" }
				)
				keymap.set(
					"n",
					"gt",
					"<cmd>Telescope lsp_type_definitions<CR>",
					{ buffer = ev.buf, desc = "Show LSP type definitions" }
				)

				-- Actions
				keymap.set(
					{ "n", "v" },
					"<leader>ca",
					vim.lsp.buf.code_action,
					{ buffer = ev.buf, desc = "See available code actions" }
				)
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = ev.buf, desc = "Smart rename" })
				keymap.set("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Show documentation under cursor" })

				-- Diagnostics
				keymap.set(
					"n",
					"<leader>D",
					"<cmd>Telescope diagnostics bufnr=0<CR>",
					{ buffer = ev.buf, desc = "Show buffer diagnostics" }
				)
				keymap.set(
					"n",
					"<leader>d",
					vim.diagnostic.open_float,
					{ buffer = ev.buf, desc = "Show line diagnostics" }
				)
				keymap.set("n", "[d", function()
					vim.diagnostic.jump({ count = -1, float = true })
				end, { buffer = ev.buf, desc = "Previous diagnostic" })
				keymap.set("n", "]d", function()
					vim.diagnostic.jump({ count = 1, float = true })
				end, { buffer = ev.buf, desc = "Next diagnostic" })

				-- Utility
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", { buffer = ev.buf, desc = "Restart LSP" })
			end,
		})

		-- Set up autocompletion capabilities
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Fix diagnostic signs - DEPRECATED, needs updating
		local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
		end

		-- Set up LSP servers with default config
		mason_lspconfig.setup_handlers({
			function(server_name)
				lspconfig[server_name].setup({
					capabilities = capabilities,
				})
			end,

			-- Configure Lua LSP with special settings
			["lua_ls"] = function()
				lspconfig["lua_ls"].setup({
					capabilities = capabilities,
					settings = {
						Lua = {
							diagnostics = { globals = { "vim" } },
							completion = { callSnippet = "Replace" },
						},
					},
				})
			end,

			-- Configure emmet language server
			["emmet_ls"] = function()
				lspconfig["emmet_ls"].setup({
					capabilities = capabilities,
					filetypes = {
						"html",
						"typescriptreact",
						"javascriptreact",
						"css",
						"sass",
						"scss",
						"less",
					},
				})
			end,
		})
	end,
}
