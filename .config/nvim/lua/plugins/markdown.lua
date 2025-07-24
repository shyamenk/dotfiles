return {

  -- Enhanced markdown rendering and icons
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      -- Basic configuration
      enabled = true,
      max_file_size = 10.0,
      debounce = 100,
      render_modes = true, -- Render in all modes
      
      -- Heading configuration
      heading = {
        enabled = true,
        sign = true,
        icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
        width = 'full',
        backgrounds = {
          'RenderMarkdownH1Bg',
          'RenderMarkdownH2Bg', 
          'RenderMarkdownH3Bg',
          'RenderMarkdownH4Bg',
          'RenderMarkdownH5Bg',
          'RenderMarkdownH6Bg',
        },
        foregrounds = {
          'RenderMarkdownH1',
          'RenderMarkdownH2',
          'RenderMarkdownH3', 
          'RenderMarkdownH4',
          'RenderMarkdownH5',
          'RenderMarkdownH6',
        },
      },
      
      -- Code blocks
      code = {
        enabled = true,
        sign = false,
        style = 'full',
        position = 'left',
        width = 'full',
        highlight = 'RenderMarkdownCode',
        highlight_inline = 'RenderMarkdownCodeInline',
      },
      
      -- Bullet points
      bullet = {
        enabled = true,
        icons = { '●', '○', '◆', '◇' },
        highlight = 'RenderMarkdownBullet',
      },
      
      -- Checkboxes - simplified
      checkbox = {
        enabled = true,
        unchecked = { icon = '󰄱 ' },
        checked = { icon = '󰱒 ' },
        custom = {
          todo = { raw = '[-]', rendered = '󰥔 ' },
          doing = { raw = '[~]', rendered = '󰪥 ' },
          delegated = { raw = '[>]', rendered = '󰪠 ' },
          cancelled = { raw = '[/]', rendered = '󰰱 ' },
          important = { raw = '[!]', rendered = '󰀪 ' },
          question = { raw = '[?]', rendered = '󰘥 ' },
        },
      },
      
      -- Tables
      pipe_table = {
        enabled = true,
        style = 'full',
        cell = 'trimmed',
        border = {
          '┌', '┬', '┐',
          '├', '┼', '┤', 
          '└', '┴', '┘',
          '│', '─',
        },
      },
      
      -- Basic callouts
      callout = {
        note = { raw = '[!NOTE]', rendered = '󰋽 Note' },
        tip = { raw = '[!TIP]', rendered = '󰌶 Tip' },
        important = { raw = '[!IMPORTANT]', rendered = '󰅾 Important' },
        warning = { raw = '[!WARNING]', rendered = '󰀪 Warning' },
        error = { raw = '[!ERROR]', rendered = '󰅖 Error' },
      },
      
      -- Links
      link = {
        enabled = true,
        image = '󰥶 ',
        email = '󰀓 ',
        hyperlink = '󰌹 ',
      },
    },
    ft = { "markdown", "norg", "rmd", "org" },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      
      -- Create toggle function manually if LazyVim.toggle is not available
      local function toggle_render_markdown()
        local render_md = require("render-markdown")
        local state = require("render-markdown.state")
        if state.enabled then
          render_md.disable()
          print("Render Markdown disabled")
        else
          render_md.enable()
          print("Render Markdown enabled")
        end
      end
      
      vim.keymap.set("n", "<leader>um", toggle_render_markdown, { desc = "Toggle Render Markdown" })
      
      -- Auto-enable for markdown files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown" },
        callback = function()
          require("render-markdown").enable()
        end,
      })
      
      -- Set up highlight groups
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          -- Heading highlights
          vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = "#f38ba8", bold = true })
          vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = "#fab387", bold = true })
          vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = "#f9e2af", bold = true })
          vim.api.nvim_set_hl(0, "RenderMarkdownH4", { fg = "#a6e3a1", bold = true })
          vim.api.nvim_set_hl(0, "RenderMarkdownH5", { fg = "#89b4fa", bold = true })
          vim.api.nvim_set_hl(0, "RenderMarkdownH6", { fg = "#cba6f7", bold = true })
          
          -- Background highlights
          vim.api.nvim_set_hl(0, "RenderMarkdownH1Bg", { bg = "#f38ba8", fg = "#1e1e2e" })
          vim.api.nvim_set_hl(0, "RenderMarkdownH2Bg", { bg = "#fab387", fg = "#1e1e2e" })
          vim.api.nvim_set_hl(0, "RenderMarkdownH3Bg", { bg = "#f9e2af", fg = "#1e1e2e" })
          vim.api.nvim_set_hl(0, "RenderMarkdownH4Bg", { bg = "#a6e3a1", fg = "#1e1e2e" })
          vim.api.nvim_set_hl(0, "RenderMarkdownH5Bg", { bg = "#89b4fa", fg = "#1e1e2e" })
          vim.api.nvim_set_hl(0, "RenderMarkdownH6Bg", { bg = "#cba6f7", fg = "#1e1e2e" })
          
          -- Code and other elements
          vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = "#313244" })
          vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { bg = "#313244", fg = "#f38ba8" })
          vim.api.nvim_set_hl(0, "RenderMarkdownBullet", { fg = "#89b4fa" })
          vim.api.nvim_set_hl(0, "RenderMarkdownLink", { fg = "#89b4fa", underline = true })
        end,
      })
      
      -- Apply highlights immediately
      vim.cmd("doautocmd ColorScheme")
    end,
  },

  -- Markdown table tools
  {
    "dhruvasagar/vim-table-mode",
    ft = { "markdown" },
    keys = {
      { "<leader>tm", "<cmd>TableModeToggle<cr>", desc = "Toggle Table Mode" },
    },
    config = function()
      vim.g.table_mode_corner = "|"
      vim.g.table_mode_corner_corner = "|"
      vim.g.table_mode_header_fillchar = "-"
    end,
  },

  -- Better markdown folding
  {
    "masukomi/vim-markdown-folding",
    ft = { "markdown" },
  },

  -- Markdown link navigation
  {
    "tadmccorkle/markdown.nvim",
    ft = "markdown",
    opts = {
      mappings = {
        inline_surround_toggle = "gs",
        inline_surround_toggle_line = "gss",
        inline_surround_delete = "ds",
        inline_surround_change = "cs",
        link_add = "gl",
        link_follow = "gx",
        go_curr_heading = "]c",
        go_parent_heading = "]p",
        go_next_heading = "]]",
        go_prev_heading = "[[",
      },
      on_attach = function(bufnr)
        local function toggle_task_list_item()
          return require("markdown").toggle_task_list_item()
        end
        vim.keymap.set("n", "<C-x>", toggle_task_list_item, { buffer = bufnr })
        vim.keymap.set("x", "<C-x>", toggle_task_list_item, { buffer = bufnr })
      end,
    },
  },

  -- Enhanced treesitter for markdown
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "markdown",
        "markdown_inline",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { "markdown" },
      },
    },
  },
}