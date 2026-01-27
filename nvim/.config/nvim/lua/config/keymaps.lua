vim.g.mapleader = " "

local keymap = vim.keymap

vim.keymap.set("n", "<leader>log", function()
  require("telescope.builtin").live_grep({ default_text = "console\\.log\\(", initial_mode = "normal" })
end, { desc = "List console.logs" })
-- Claude Code
keymap.set("n", "<leader>cc", "<cmd>ClaudeCode<CR>", { desc = "Toggle Claude Code" })

-- General Keymaps
keymap.set("n", "-", "<CMD>Oil --float<CR>", { desc = "Open parent directory" })
keymap.set("n", "<leader><left>", ":vertical resize +20<CR>", { desc = "Increase Vertical Window Size" })
keymap.set("n", "<leader><right>", ":vertical resize -20<CR>", { desc = "Decrease Vertical Window Size" })
keymap.set("n", "<leader><up>", ":resize +10<CR>", { desc = "Increase Horizontal Window Size" })
keymap.set("n", "<leader><down>", ":resize -10<CR>", { desc = "Decrease Horizontal Window Size" })
vim.keymap.set("n", "gp", "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", { noremap = true })
-- Exit insert mode with 'jj'
keymap.set("i", "jj", "<ESC>", { desc = "Exit Insert Mode" })

-- Select all
keymap.set("n", "==", "gg<S-v>G", { desc = "Select All" })
--- Center the screen after scrolling up/down with Ctrl-u/d
keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up" })
keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down" })

-- move a blocks of text up/down with K/J in visual mode
keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move Block Up" })
keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move Block Down" })

-- Center the screen on the next/prev search result with n/N
keymap.set("n", "n", "nzzzv", { desc = "Center The Screen On Next Search Result" })
keymap.set("n", "N", "Nzzzv", { desc = "Center The Screen On Prev Search Result" })

-- Clear search highlights
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear Search Highlights" })

-- Force quit without saving
keymap.set("n", "QQ", ":q!<enter>", { desc = "Force Quit Without Saving" })

-- Save file
keymap.set("n", "<C-s>", ":w<CR>", { desc = "Save File" })

-- Quick close
keymap.set("n", "<leader>qq", ":q<CR>", { desc = "Quick Close" })

-- Delete single character without copying into register
keymap.set("n", "x", '"_x', { desc = "Delete Single Character Without Copying Into Register" })

-- Dismiss Noice notifications
keymap.set("n", "<leader>nn", ":Noice dismiss<CR>", { noremap = true, desc = "Dismiss Noice Notifications" })

-------------------------
-- Window Management --
-------------------------

-- Split window vertically
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split Window Vertically" })

-- Split window horizontally
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split Window Horizontally" })

-- Make split windows equal size
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make Split Windows Equal Size" })

-- Close current split window
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close Split Window" })

---------------------------
-- Diagnostic Keymaps --
---------------------------

keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go To Previous Diagnostic" })
keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go To Next Diagnostic" })
keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open Diagnostics List" })
keymap.set(
  "n",
  "<leader><leader>",
  "<cmd>lua require('goto-preview').close_all_win()<CR>",
  { noremap = true, desc = "Close All Preview Windows" }
)

-----------------------
-- Obsidian Keymaps --
-----------------------

keymap.set("n", "<leader>oo", "<cmd>ObsidianOpen<CR>", { desc = "Open Obsidian" })
keymap.set("n", "<leader>od", "<cmd>ObsidianDailies<CR>", { desc = "Show ObsidianDailies" })
keymap.set("n", "<leader>ob", "<cmd>ObsidianBacklinks<CR>", { desc = "Show ObsidianBacklinks" })
keymap.set("n", "<leader>ol", "<cmd>ObsidianLinks<CR>", { desc = "Show ObsidianLinks" })
keymap.set("n", "<leader>on", "<cmd>ObsidianNew<CR>", { desc = "Create New Note" })
keymap.set("n", "<leader>os", "<cmd>ObsidianSearch<CR>", { desc = "Search Obsidian Notes" })
keymap.set("n", "<leader>oq", "<cmd>ObsidianQuickSwitch<CR>", { desc = "Quick Switch Obsidian Notes" })
keymap.set("n", "<leader>ot", "<cmd>ObsidianTemplate<CR>", { desc = "Create New Note from Template" })

-----------------------
-- Markdown Keymaps --
-----------------------

-- Markdown preview
keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Markdown Preview (Browser)" })
keymap.set("n", "<leader>mg", "<cmd>Glow<cr>", { desc = "Markdown Preview (Terminal)" })
keymap.set("n", "<leader>mps", "<cmd>MarkdownPreviewStop<cr>", { desc = "Markdown Preview Stop" })

-- Table mode toggle
keymap.set("n", "<leader>tm", "<cmd>TableModeToggle<cr>", { desc = "Toggle Table Mode" })

-- Render markdown toggle (will be overridden by plugin config)

-- Checkbox management
keymap.set("n", "<leader>tc", function()
  -- Try markdown-togglecheck first, fallback to markdown.nvim
  local ok, togglecheck = pcall(require, "markdown-togglecheck")
  if ok then
    togglecheck.toggle()
  else
    -- Fallback to markdown.nvim toggle
    local ok2, markdown = pcall(require, "markdown")
    if ok2 then
      return markdown.toggle_task_list_item()
    end
  end
end, { desc = "Toggle checkbox state" })

-- Bullets toggle
keymap.set("n", "<leader>x", "<Plug>(bullets-toggle-checkbox)", { desc = "Toggle bullet checkbox" })

-- Manual formatting
keymap.set("n", "<leader>cf", function()
  require("conform").format({ async = true, lsp_fallback = true })
end, { desc = "Format current buffer" })

-- Enable Twilight plugin
keymap.set("n", "<leader>tw", ":Twilight<enter>", { desc = "Enable Twilight Mode" })
