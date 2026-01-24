# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a **LazyVim-based Neovim configuration** that follows a modular plugin architecture. The configuration is part of a larger dotfiles repository and uses modern Neovim practices with lazy loading and Mason for tool management.

### Key Structure
- **init.lua**: Bootstraps lazy.nvim plugin manager
- **lua/config/**: Core configuration (options, keymaps, autocmds, lazy setup)
- **lua/plugins/**: Individual plugin specifications in separate files
- **lazy-lock.json**: Version-locked plugin dependencies (auto-managed)

### Configuration Patterns
- Each plugin gets its own file in `lua/plugins/` returning a table/array of specs
- LazyVim core is imported with `{ "LazyVim/LazyVim", import = "lazyvim.plugins" }`
- Custom plugins imported with `{ import = "plugins" }`
- Use LazyVim extras system for language support (e.g., `lazyvim.plugins.extras.lang.typescript`)

## Key Features & Tools

### Development Setup
- **Primary Language**: TypeScript with full LSP, ESLint, Prettier integration
- **Tool Management**: Mason auto-installs language servers, linters, formatters
- **Theme**: Catppuccin (mocha flavor) with fallbacks to Tokyo Night, Habamax
- **File Manager**: Oil.nvim (replaces netrw)
- **Terminal**: ToggleTerm with floating window configuration
- **Completion**: Blink.cmp with filetype-specific sources and enhanced shortcuts

### Note-Taking & Markdown Integration
- **Obsidian.nvim**: Full integration with Obsidian vault at `~/Documents/Second Brain`
- **Markdown Preview**: Live browser preview with dark theme support
- **Enhanced Rendering**: Beautiful icons for headings, checkboxes, bullets, and callouts
- **Table Mode**: Easy table creation and editing with auto-formatting
- **Checkbox Management**: 8 different checkbox states with proper icons
- **Smart Lists**: Auto-indentation, bullet cycling, and list management
- **Callouts**: 20+ GitHub/Obsidian-style admonitions with icons

### Custom Keymaps
- **Leader**: Space key
- **Quick Exit**: `jj` from insert mode to normal mode
- **File Navigation**: `-` opens Oil file manager
- **Window Resize**: Leader + arrow keys
- **Console.log Search**: Custom Telescope command for JavaScript debugging

## Common Commands

### Plugin Management
```vim
:Lazy                    " Open plugin manager UI
:Lazy sync              " Update plugins
:Lazy clean             " Remove unused plugins
```

### Tool Management
```vim
:Mason                  " Open Mason UI for LSP/tools
:MasonInstall <tool>    " Install specific tool
:checkhealth mason      " Check Mason status
```

### Development Workflow
```vim
:checkhealth            " Full health check
:LspInfo               " Show LSP status
:LspRestart            " Restart language servers
```

### Code Formatting
- **Lua**: Uses Stylua with 2-space indentation (configured in stylua.toml)
- **TypeScript/JavaScript**: Uses Prettier via none-ls
- **Auto-format**: Configured to format on save where appropriate

## Complete Keymap Reference

### Core Navigation & Editing
| Key | Command | Description |
|-----|---------|-------------|
| `jj` | `<ESC>` | Exit insert mode |
| `-` | `:Oil --float<CR>` | Open parent directory |
| `==` | `gg<S-v>G` | Select all text |
| `<C-u>` | `<C-u>zz` | Scroll up and center |
| `<C-d>` | `<C-d>zz` | Scroll down and center |
| `n` | `nzzzv` | Next search result (centered) |
| `N` | `Nzzzv` | Previous search result (centered) |
| `x` | `"_x` | Delete character without copying |
| `<C-s>` | `:w<CR>` | Save file |
| `QQ` | `:q!<enter>` | Force quit without saving |

### Window Management
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>sv` | `<C-w>v` | Split window vertically |
| `<leader>sh` | `<C-w>s` | Split window horizontally |
| `<leader>se` | `<C-w>=` | Make split windows equal size |
| `<leader>sx` | `:close<CR>` | Close current split window |
| `<leader><left>` | `:vertical resize +20<CR>` | Increase vertical window size |
| `<leader><right>` | `:vertical resize -20<CR>` | Decrease vertical window size |
| `<leader><up>` | `:resize +10<CR>` | Increase horizontal window size |
| `<leader><down>` | `:resize -10<CR>` | Decrease horizontal window size |

### Tab Management
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>to` | `:tabnew<CR>` | Open new tab |
| `<leader>tx` | `:tabclose<CR>` | Close current tab |
| `<leader>tn` | `:tabn<CR>` | Go to next tab |
| `<leader>tp` | `:tabp<CR>` | Go to previous tab |
| `<leader>tf` | `:tabnew %<CR>` | Open current buffer in new tab |

### Obsidian Integration
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>oo` | `:ObsidianOpen<CR>` | Open Obsidian app |
| `<leader>od` | `:ObsidianDailies<CR>` | Show daily notes |
| `<leader>ob` | `:ObsidianBacklinks<CR>` | Show backlinks |
| `<leader>ol` | `:ObsidianLinks<CR>` | Show all links |
| `<leader>on` | `:ObsidianNew<CR>` | Create new note |
| `<leader>os` | `:ObsidianSearch<CR>` | Search notes |
| `<leader>oq` | `:ObsidianQuickSwitch<CR>` | Quick switch notes |
| `<leader>ot` | `:ObsidianTemplate<CR>` | Create note from template |

### Markdown Editing
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>mp` | `:MarkdownPreviewToggle<cr>` | Toggle markdown preview |
| `<leader>tm` | `:TableModeToggle<cr>` | Toggle table mode |
| `<leader>um` | `:RenderMarkdown toggle<cr>` | Toggle markdown rendering |
| `<leader>tc` | `markdown-togglecheck.toggle()` | Toggle checkbox state |
| `<leader>x` | `<Plug>(bullets-toggle-checkbox)` | Toggle bullet checkbox |
| `<C-x>` | `markdown.toggle_task_list_item()` | Toggle task list item |
| `]]` | Go to next heading | Navigate to next heading |
| `[[` | Go to previous heading | Navigate to previous heading |
| `gx` | Follow link | Follow markdown link |

### Completion Shortcuts (Insert Mode)
| Key | Command | Description |
|-----|---------|-------------|
| `<C-space>` | Trigger completion | Show/trigger completion menu |
| `<CR>` | Accept completion | Accept selected completion |
| `<Tab>` | Next completion/snippet | Navigate completion or snippet |
| `<S-Tab>` | Previous completion/snippet | Navigate back in completion |
| `<C-n>` | Next item | Select next completion item |
| `<C-p>` | Previous item | Select previous completion item |
| `<C-e>` | Hide completion | Hide completion menu |
| `<C-u>` | Scroll docs up | Scroll documentation up |
| `<C-d>` | Scroll docs down | Scroll documentation down |

### Diagnostic Navigation
| Key | Command | Description |
|-----|---------|-------------|
| `[d` | `vim.diagnostic.goto_prev` | Go to previous diagnostic |
| `]d` | `vim.diagnostic.goto_next` | Go to next diagnostic |
| `<leader>q` | `vim.diagnostic.setloclist` | Open diagnostics list |

### Visual Mode Enhancements
| Key | Command | Description |
|-----|---------|-------------|
| `K` | `:m '<-2<CR>gv=gv` | Move block up |
| `J` | `:m '>+1<CR>gv=gv` | Move block down |

### Search & Utility
| Key | Command | Description |
|-----|---------|-------------|
| `<leader>log` | `Telescope live_grep console\\.log` | Search for console.log statements |
| `<leader>nh` | `:nohl<CR>` | Clear search highlights |
| `<leader>nn` | `:Noice dismiss<CR>` | Dismiss Noice notifications |
| `<leader>qq` | `:q<CR>` | Quick close |
| `<leader>tw` | `:Twilight<enter>` | Enable Twilight mode |

## Adding New Functionality

### New Plugins
1. Create new file in `lua/plugins/filename.lua`
2. Return table with plugin specifications
3. Restart Neovim or run `:Lazy reload`

### Language Support
1. Use LazyVim extras: `{ import = "lazyvim.plugins.extras.lang.python" }`
2. Or manually configure LSP in existing plugin files
3. Add tools to Mason ensure_installed lists

### Theme Changes
- Modify `lua/plugins/catppuccin.lua` for Catppuccin customization
- Add new theme files following the same pattern
- Update LazyVim colorscheme option

## Architecture Notes

### Plugin Loading Strategy
- Uses lazy loading for performance
- Priority system ensures themes load first (priority = 1000)
- Dependencies are automatically managed

### Configuration Inheritance
- Builds on LazyVim defaults
- Custom configurations override/extend defaults using opts tables
- Plugin specs can use functions for dynamic configuration

### File Organization
- Separate concerns: one plugin per file when complex
- Group related simple plugins in single files
- Use descriptive filenames matching plugin purpose

### Development Workflow
- Configuration changes are immediately applied (no build step)
- Lock file maintains reproducible plugin versions
- Git integration shows modified configuration files

## Installed Plugins & Their Purposes

### Core LazyVim Infrastructure
- **LazyVim**: Base configuration framework
- **lazy.nvim**: Plugin manager with lazy loading
- **which-key.nvim**: Command discovery and help system
- **snacks.nvim**: Collection of utility functions

### UI & Theming
- **catppuccin**: Primary colorscheme (Mocha flavor)
- **tokyonight.nvim**: Fallback colorscheme
- **lualine.nvim**: Status line with customizations
- **bufferline.nvim**: Tab-like buffer management
- **noice.nvim**: Enhanced UI for messages and cmdline
- **mini.icons**: Icon provider for file types

### File Management & Navigation
- **oil.nvim**: File manager (replaces netrw)
- **telescope.nvim**: Fuzzy finder and picker
- **flash.nvim**: Enhanced navigation and search
- **grug-far.nvim**: Find and replace across files

### Completion & LSP
- **blink.cmp**: Modern completion engine
- **nvim-lspconfig**: LSP client configurations
- **mason.nvim**: LSP/tool installer
- **mason-lspconfig.nvim**: Mason-LSP integration
- **lazydev.nvim**: Enhanced Lua development
- **SchemaStore.nvim**: JSON schema support

### Language Support
- **nvim-treesitter**: Syntax highlighting and parsing
- **nvim-treesitter-textobjects**: Text objects based on syntax
- **nvim-ts-autotag**: Auto-close HTML/JSX tags
- **ts-comments.nvim**: Better comment handling
- **friendly-snippets**: Collection of useful snippets

### Code Quality & Formatting
- **conform.nvim**: Code formatting
- **nvim-lint**: Linting integration
- **trouble.nvim**: Diagnostics and quickfix list
- **todo-comments.nvim**: Highlight TODO comments

### Git Integration
- **gitsigns.nvim**: Git signs in gutter and more
- **persistence.nvim**: Session management

### Terminal & Development
- **toggleterm.nvim**: Terminal integration
- **mini.pairs**: Auto-pair brackets and quotes
- **mini.ai**: Enhanced text objects

### Markdown & Note-Taking
- **obsidian.nvim**: Obsidian vault integration
- **markdown-preview.nvim**: Live markdown preview in browser
- **render-markdown.nvim**: Enhanced markdown rendering with icons
- **markdown.nvim**: Advanced markdown editing features
- **vim-table-mode**: Easy table creation and editing
- **vim-markdown**: Enhanced markdown syntax and features
- **vim-markdown-folding**: Better folding for markdown
- **bullets.vim**: Smart bullet list management
- **autolist.nvim**: Automatic list continuation and formatting
- **markdown-togglecheck**: Checkbox state cycling
- **treesitter-utils**: Utilities for markdown plugins

### Dependencies
- **plenary.nvim**: Lua utility functions (required by many plugins)
- **nui.nvim**: UI component library

## Markdown Rendering Features

### Checkbox States
- `[ ]` → `󰄱 ` Unchecked (todo)
- `[x]` → `󰱒 ` Checked (done)
- `[-]` → `󰥔 ` Partial (in progress)
- `[~]` → `󰪥 ` Doing (active)
- `[>]` → `󰪠 ` Delegated (forwarded)
- `[/]` → `󰰱 ` Cancelled (crossed out)
- `[!]` → `󰀪 ` Important (priority)
- `[?]` → `󰘥 ` Question (unclear)

### Bullet Types
- Level 1: `●` (solid circle)
- Level 2: `○` (hollow circle)
- Level 3: `◆` (solid diamond)
- Level 4: `◇` (hollow diamond)

### Callout Types (GitHub/Obsidian Style)
- `[!NOTE]` → `󰋽 Note` (blue)
- `[!TIP]` → `󰌶 Tip` (green)
- `[!IMPORTANT]` → `󰅾 Important` (purple)
- `[!WARNING]` → `󰀪 Warning` (yellow)
- `[!CAUTION]` → `󰳦 Caution` (orange)
- `[!ERROR]` → `󰅖 Error` (red)
- Plus 15+ more callout types with appropriate icons and colors

## Recent Changes & Additions

### 2024-07-23 - Major Markdown & Completion Overhaul
#### Added:
- **Catppuccin Theme**: Primary colorscheme with Mocha flavor
- **TypeScript Development Suite**: Complete LSP, linting, formatting setup
- **Comprehensive Markdown System**: 
  - Live preview with markdown-preview.nvim
  - Enhanced rendering with proper icons and spacing
  - 8 different checkbox states with Nerd Font icons
  - Smart bullet and list management
  - Table mode for easy table editing
  - 20+ callout/admonition types
- **Enhanced Completion**: Fixed blink.cmp integration, removed nvim-cmp conflicts
- **Obsidian Integration**: Full vault integration with proper UI and keymaps

#### Fixed:
- Blink.cmp source errors (removed non-existent Obsidian sources)
- Obsidian plugin dependency issues
- Markdown rendering spacing and icon alignment
- LazyVim import order (lazyvim.plugins → extras → custom plugins)

#### Plugin Files Added:
- `lua/plugins/catppuccin.lua` - Theme configuration
- `lua/plugins/typescript.lua` - TypeScript development tools
- `lua/plugins/completion.lua` - Enhanced completion setup
- `lua/plugins/markdown.lua` - Markdown preview and rendering
- `lua/plugins/markdown-enhance.lua` - Additional markdown tools
- `lua/plugins/obsidian.lua` - Obsidian vault integration

#### Mason Tools Installed:
- typescript-language-server
- eslint-lsp
- prettier, prettierd
- js-debug-adapter

### Import Order Configuration
The LazyVim plugin loading follows the correct order:
1. `{ "LazyVim/LazyVim", import = "lazyvim.plugins" }` - Core LazyVim
2. `{ import = "lazyvim.plugins.extras.lang.typescript" }` - LazyVim extras
3. `{ import = "plugins" }` - Custom plugins

This ensures proper initialization and prevents conflicts between LazyVim core features and custom configurations.