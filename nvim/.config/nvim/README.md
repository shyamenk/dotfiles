# Neovim Configuration

A LazyVim-based Neovim configuration optimized for modern development workflows.

## Features

- **LSP Support**: Full language server integration with Mason for automatic installation
- **Completion**: Blink.cmp with filetype-specific sources
- **Theme**: Catppuccin (Mocha) with fallbacks
- **File Manager**: Oil.nvim for seamless file navigation
- **Single Buffer Workflow**: No tabs/bufferline for distraction-free editing

## Supported Languages

| Language | LSP | Linter | Formatter |
|----------|-----|--------|-----------|
| TypeScript/JavaScript | typescript-language-server | eslint | prettier |
| Python | pyright | ruff | ruff |
| YAML | yaml-language-server | yamllint | - |
| Docker | dockerfile-language-server | hadolint | - |
| Lua | lua_ls | - | stylua |
| Markdown | marksman | - | - |

## Key Plugins

| Plugin | Purpose |
|--------|---------|
| LazyVim | Base configuration framework |
| blink.cmp | Modern completion engine |
| telescope.nvim | Fuzzy finder |
| oil.nvim | File manager |
| catppuccin | Colorscheme |
| gitsigns.nvim | Git integration |
| treesitter | Syntax highlighting |
| mason.nvim | Tool installer |

## Quick Keymaps

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `jj` | Exit insert mode |
| `-` | Open file manager |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>sv` | Split vertical |
| `<leader>sh` | Split horizontal |

## Requirements

- Neovim 0.9+
- Git
- A [Nerd Font](https://www.nerdfonts.com/) for icons
- Node.js (for LSP servers)
- ripgrep (for telescope grep)

## Installation

This configuration is managed via GNU Stow as part of a dotfiles repository:

```bash
cd ~/dotfiles
stow nvim
```

After installation, open Neovim and run `:Lazy sync` to install plugins.

## Verification

After setup, verify the configuration:

1. `:Lazy` - Check plugin status
2. `:Mason` - Verify LSP/tool installation
3. `:LspInfo` - Check active language servers
4. `:checkhealth` - Run health checks
