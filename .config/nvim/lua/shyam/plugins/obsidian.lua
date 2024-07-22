return {
	"epwalsh/obsidian.nvim",
	-- tag = "*",
	requires = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		require("obsidian").setup({
			workspaces = {
				{
					name = "notes",
					path = "~/Documents/Notes",
				},
			},

			notes_subdir = "inbox",
			new_notes_location = "notes_subdir",

			note_id_func = function(title)
				local suffix = ""
				if title ~= nil then
					suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
				else
					for _ = 1, 4 do
						suffix = suffix .. string.char(math.random(65, 90))
					end
				end
				return suffix .. ".md"
			end,

			-- note_frontmatter_func = function(note)
			-- 	if note.title then
			-- 		note:add_alias(note.title)
			-- 	end
			--
			-- 	local out = {
			-- 		id = note.id,
			-- 		aliases = note.aliases,
			-- 		tags = note.tags,
			-- 	}
			--
			-- 	if note.metadata then
			-- 		for k, v in pairs(note.metadata) do
			-- 			out[k] = v
			-- 		end
			-- 	end
			--
			-- 	if not out.url then
			-- 		out.author = "shyamenk@gmail.com"
			-- 		out.reference = "https://example.com"
			-- 	end
			--
			-- 	return out
			-- end,
			templates = {
				subdir = "Templates",
				date_format = "%Y-%m-%d",
				time_format = "%H:%M:%S",
			},

			daily_notes = {
				folder = "Daily Notes",
			},
			completion = {
				nvim_cmp = true,
				min_chars = 2,
			},
			ui = {
				enable = true,
			},
		})
	end,
}
