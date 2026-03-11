return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  cmd = {
    "ObsidianOpen",
    "ObsidianNew",
    "ObsidianQuickSwitch",
    "ObsidianFollowLink",
    "ObsidianBacklinks",
    "ObsidianTags",
    "ObsidianToday",
    "ObsidianYesterday",
    "ObsidianTomorrow",
    "ObsidianDailies",
    "ObsidianTemplate",
    "ObsidianSearch",
    "ObsidianLink",
    "ObsidianLinkNew",
    "ObsidianLinks",
    "ObsidianExtractNote",
    "ObsidianWorkspace",
    "ObsidianPasteImg",
    "ObsidianRename",
  },
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("obsidian").setup({
      workspaces = {
        {
          name = "vault2",
          path = "~/Documents/Second Brain",
        },
      },
      notes_subdir = "inbox",
      new_notes_location = "notes_subdir",
      note_id_func = function(title)
        return title
      end,
      note_frontmatter_func = function(note)
        local out = {
          id = tostring(os.time()),
          tags = note.tags or {},
          ["created at"] = os.date("%Y-%m-%d"),
          title = note.title,
        }
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end
        return out
      end,
      templates = {
        subdir = "templates",
        date_format = "%d-%m-%Y",
        time_format = "%H:%M",
        substitutions = {},
      },
      daily_notes = {
        folder = "daily",
        date_format = "%d-%m-%Y",
        alias_format = "%B %-d, %Y",
        default_tags = { "daily-notes" },
        template = "daily-note.md",
      },
      completion = {
        nvim_cmp = false, -- Disable nvim-cmp integration since we use blink.cmp
        min_chars = 2,
      },
      wiki_link_func = function(opts)
        if opts.id == nil then
          return string.format("[[%s]]", opts.label)
        elseif opts.label ~= opts.id then
          return string.format("[[%s|%s]]", opts.id, opts.label)
        else
          return string.format("[[%s]]", opts.id)
        end
      end,
      preferred_link_style = "wiki",
      open_notes_in = "current",
      mappings = {
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        ["<cr>"] = {
          action = function()
            return require("obsidian").util.smart_action()
          end,
          opts = { buffer = true, expr = true },
        },
      },
      follow_url_func = function(url)
        vim.fn.jobstart({ "xdg-open", url }) -- linux
      end,
      open_app_foreground = false,
    })
  end,
}
