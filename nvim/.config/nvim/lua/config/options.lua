local opt = vim.opt

vim.filetype.add({
  extension = {
    mdx = "mdx",
  },
})

-- General settings
opt.conceallevel = 2
opt.relativenumber = true
opt.number = true

-- Tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- Line wrapping
opt.wrap = true
opt.linebreak = true
opt.formatoptions:append("t")
opt.textwidth = 0

-- Search settings
opt.ignorecase = true
opt.smartcase = true

-- Cursor line
opt.cursorline = true
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

-- Backspace
opt.backspace = "indent,eol,start"

-- Clipboard
opt.clipboard:append("unnamedplus")

-- Split windows
opt.splitright = true
opt.splitbelow = true

-- Turn off swapfile
opt.swapfile = false

-- Disable tabline for single-buffer workflow
opt.showtabline = 0

-- Performance & UX enhancements
opt.updatetime = 200 -- Faster diagnostics & CursorHold (default 4000ms)
opt.scrolloff = 8 -- Keep cursor away from screen edge
opt.sidescrolloff = 8 -- Horizontal scroll margin
opt.pumheight = 10 -- Limit completion menu height
opt.inccommand = "split" -- Live preview for substitutions
opt.timeoutlen = 300 -- Faster keymap timeout
