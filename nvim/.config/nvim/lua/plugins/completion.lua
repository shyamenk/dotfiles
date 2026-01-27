return {
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      -- Base sources
      opts.sources = opts.sources or {}
      opts.sources.default = { "lsp", "path", "snippets", "buffer" }

      -- Filetype-specific sources
      opts.sources.per_filetype = {
        markdown = { "lsp", "path", "snippets", "buffer" },
        typescript = { "lsp", "path", "snippets", "buffer" },
        javascript = { "lsp", "path", "snippets", "buffer" },
        lua = { "lsp", "path", "snippets", "buffer", "lazydev" },
        json = { "lsp", "path", "snippets", "buffer" },
        yaml = { "lsp", "path", "snippets", "buffer" },
        dockerfile = { "lsp", "path", "snippets", "buffer" },
      }

      -- Completion settings
      opts.completion = {
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "source_name" },
            },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
      }

      -- Keymaps
      opts.keymap = {
        preset = "default",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
      }

      return opts
    end,
  },

  -- Telescope integration improvements
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
      },
    },
  },
}
