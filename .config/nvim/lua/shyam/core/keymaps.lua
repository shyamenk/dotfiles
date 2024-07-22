vim.g.mapleader = " "

local keymap = vim.keymap
-- General Keymaps

keymap.set("n", "<leader><left>", ":vertical resize +20<CR>", { desc = "Increase Vertical Window Size" })
keymap.set("n", "<leader><right>", ":vertical resize -20<CR>", { desc = "Decrease Vertical Window Size" })
keymap.set("n", "<leader><up>", ":resize +10<CR>", { desc = "Increase Horizontal Window Size" })
keymap.set("n", "<leader><down>", ":resize -10<CR>", { desc = "Decrease Horizontal Window Size" })

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
keymap.set("n", "<leader>nn", ":Noice dismiss<CR>", { noremap = true, desc = "Dismis Noice Notifications" })

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

---------------------
-- Tab Management --
---------------------

-- Open new tab
keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open New Tab" })

-- Close current tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close Current Tab" })

-- Go to next tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go To Next Tab" })

-- Go to previous tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go To Previous Tab" })

-- Open current buffer in new tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open Current Buffer in New Tab" })

-------------------------
-- Highlight on Yank --
-------------------------

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})

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

-- Enable Twilight plugin
keymap.set("n", "<leader>tw", ":Twilight<enter>", { desc = "Enable Twilight Mode" })
