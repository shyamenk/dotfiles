return {
	{
		"tpope/vim-fugitive",
		event = { "BufReadPre", "BufNewFile" },
		cmd = {
			"G",
		},
	},
}
