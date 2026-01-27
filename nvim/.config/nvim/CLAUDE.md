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
| Key | Mode | Description |
|-----|------|-------------|
| `jj` | Insert | Exit insert mode |
| `-` | Normal | Open Oil file manager (floating) |
| `==` | Normal | Select all text |
| `<C-u>` | Normal | Scroll up and center |
| `<C-d>` | Normal | Scroll down and center |
| `n` | Normal | Next search result (centered) |
| `N` | Normal | Previous search result (centered) |
| `x` | Normal | Delete character without copying |
| `<C-s>` | Normal | Save file |
| `QQ` | Normal | Force quit without saving |
| `gp` | Normal | Go to preview definition |

### Window Management
| Key | Mode | Description |
|-----|------|-------------|
| `<leader>sv` | Normal | Split window vertically |
| `<leader>sh` | Normal | Split window horizontally |
| `<leader>se` | Normal | Make split windows equal size |
| `<leader>sx` | Normal | Close current split window |
| `<leader><left>` | Normal | Increase vertical window size |
| `<leader><right>` | Normal | Decrease vertical window size |
| `<leader><up>` | Normal | Increase horizontal window size |
| `<leader><down>` | Normal | Decrease horizontal window size |
| `<leader><leader>` | Normal | Close all preview windows |

### Terminal (ToggleTerm)
| Key | Mode | Description |
|-----|------|-------------|
| `<C-\>` | Normal/Terminal | Toggle terminal (floating) |
| `<leader>th` | Normal | Terminal horizontal split |
| `<leader>tv` | Normal | Terminal vertical split (80 width) |
| `<leader>tf` | Normal | Terminal floating window |

### Obsidian Integration
| Key | Mode | Description |
|-----|------|-------------|
| `<leader>oo` | Normal | Open Obsidian app |
| `<leader>od` | Normal | Show daily notes |
| `<leader>ob` | Normal | Show backlinks |
| `<leader>ol` | Normal | Show all links |
| `<leader>on` | Normal | Create new note |
| `<leader>os` | Normal | Search notes |
| `<leader>oq` | Normal | Quick switch notes |
| `<leader>ot` | Normal | Create note from template |
| `gf` | Normal | Follow link (passthrough) |
| `<CR>` | Normal | Smart action (in markdown) |

### Markdown Editing
| Key | Mode | Description |
|-----|------|-------------|
| `<leader>mp` | Normal | Toggle markdown preview (browser) |
| `<leader>mg` | Normal | Markdown preview (Glow terminal) |
| `<leader>mps` | Normal | Stop markdown preview |
| `<leader>tm` | Normal | Toggle table mode |
| `<leader>um` | Normal | Toggle render markdown |
| `<leader>tc` | Normal | Toggle checkbox state |
| `<leader>x` | Normal | Toggle bullet checkbox |
| `<C-x>` | Normal/Visual | Toggle task list item |
| `]]` | Normal | Go to next heading |
| `[[` | Normal | Go to previous heading |
| `]c` | Normal | Go to current heading |
| `]p` | Normal | Go to parent heading |
| `gx` | Normal | Follow link |
| `gs` | Normal | Inline surround toggle |
| `gss` | Normal | Inline surround toggle line |
| `ds` | Normal | Inline surround delete |
| `cs` | Normal | Inline surround change |
| `gl` | Normal | Add link |

### Completion (Blink.cmp - Insert Mode)
| Key | Description |
|-----|-------------|
| `<C-space>` | Show/toggle completion & documentation |
| `<CR>` | Accept completion |
| `<Tab>` | Snippet forward / fallback |
| `<S-Tab>` | Snippet backward / fallback |
| `<Up>` / `<C-p>` | Select previous item |
| `<Down>` / `<C-n>` | Select next item |
| `<C-e>` | Hide completion menu |
| `<C-u>` | Scroll documentation up |
| `<C-d>` | Scroll documentation down |

### Diagnostic Navigation
| Key | Mode | Description |
|-----|------|-------------|
| `[d` | Normal | Go to previous diagnostic |
| `]d` | Normal | Go to next diagnostic |
| `<leader>q` | Normal | Open diagnostics list |

### Visual Mode Enhancements
| Key | Mode | Description |
|-----|------|-------------|
| `K` | Visual | Move block up |
| `J` | Visual | Move block down |

### Search & Utility
| Key | Mode | Description |
|-----|------|-------------|
| `<leader>log` | Normal | Search for console.log statements |
| `<leader>nh` | Normal | Clear search highlights |
| `<leader>nn` | Normal | Dismiss Noice notifications |
| `<leader>qq` | Normal | Quick close |
| `<leader>tw` | Normal | Enable Twilight mode |
| `<leader>cf` | Normal | Format current buffer (Conform) |

### Claude Code Integration
| Key | Mode | Description |
|-----|------|-------------|
| `<leader>cc` | Normal | Toggle Claude Code |

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