return {
	"iamcco/markdown-preview.nvim",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	ft = { "markdown" },
	build = function()
		vim.fn["mkdp#util#install"]()
	end,
	init = function()
		vim.g.mkdp_theme = "dark"
	end,
	keys = {
		{ "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview (Browser)" },
		{ "<leader>mps", "<cmd>MarkdownPreviewStop<cr>", desc = "Stop Markdown Preview" },
	},
}
