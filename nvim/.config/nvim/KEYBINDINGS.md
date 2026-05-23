# Neovim Keybindings Reference

> Leader = `Space`

---

## General Editing

| Key          | Mode   | Description                        |
| ------------ | ------ | ---------------------------------- |
| `jj`         | Insert | Exit insert mode                   |
| `<C-s>`      | Normal | Save file                          |
| `QQ`         | Normal | Force quit without saving          |
| `<leader>qq` | Normal | Close window                       |
| `==`         | Normal | Select all                         |
| `x`          | Normal | Delete char (no register)          |
| `<C-u>`      | Normal | Scroll up + center                 |
| `<C-d>`      | Normal | Scroll down + center               |
| `n` / `N`    | Normal | Next/prev search result (centered) |
| `<leader>nh` | Normal | Clear search highlights            |
| `K`          | Visual | Move block up                      |
| `J`          | Visual | Move block down                    |

---

## Window Management

| Key                | Mode   | Description                    |
| ------------------ | ------ | ------------------------------ |
| `<leader>sv`       | Normal | Split vertical                 |
| `<leader>sh`       | Normal | Split horizontal               |
| `<leader>se`       | Normal | Equal split sizes              |
| `<leader>sx`       | Normal | Close split                    |
| `<leader><left>`   | Normal | Widen vertical split (+20)     |
| `<leader><right>`  | Normal | Narrow vertical split (-20)    |
| `<leader><up>`     | Normal | Taller horizontal split (+10)  |
| `<leader><down>`   | Normal | Shorter horizontal split (-10) |
| `<leader><leader>` | Normal | Close all floating windows     |

---

## File Manager (Oil)

| Key     | Mode   | Description                  |
| ------- | ------ | ---------------------------- |
| `-`     | Normal | Open Oil float (current dir) |
| `q`     | Oil    | Close Oil                    |
| `<C-v>` | Oil    | Open in vertical split       |
| `<C-s>` | Oil    | Open in horizontal split     |
| `<C-r>` | Oil    | Refresh                      |

---

## LSP & Diagnostics

| Key          | Mode   | Description                     |
| ------------ | ------ | ------------------------------- |
| `gp`         | Normal | Peek definition (open in split) |
| `[d`         | Normal | Previous diagnostic             |
| `]d`         | Normal | Next diagnostic                 |
| `<leader>q`  | Normal | Open diagnostics list           |
| `<leader>cl` | Normal | Trigger linting manually        |
| `<leader>cf` | Normal | Format buffer (Conform)         |

> LazyVim also provides: `gd` goto def, `gr` references, `K` hover, `<leader>ca` code action, `<leader>cr` rename

---

## Terminal (ToggleTerm)

| Key          | Mode            | Description                       |
| ------------ | --------------- | --------------------------------- |
| `<C-\>`      | Normal/Terminal | Toggle floating terminal          |
| `<leader>th` | Normal          | Terminal horizontal split         |
| `<leader>tv` | Normal          | Terminal vertical split (80 cols) |
| `<leader>tf` | Normal          | Terminal float                    |

---

## Claude Code

| Key          | Mode            | Description                |
| ------------ | --------------- | -------------------------- |
| `<leader>ai` | Normal/Terminal | Toggle Claude Code panel   |
| `<leader>aC` | Normal          | Continue last conversation |
| `<leader>aV` | Normal          | Verbose mode               |

---

## Obsidian

| Key          | Mode   | Description                                  |
| ------------ | ------ | -------------------------------------------- |
| `<leader>oo` | Normal | Open Obsidian app                            |
| `<leader>oy` | Normal | Today's daily note                           |
| `<leader>od` | Normal | Browse daily notes                           |
| `<leader>on` | Normal | New note                                     |
| `<leader>ot` | Normal | New note from template (picker)              |
| `<leader>os` | Normal | Search notes (full text)                     |
| `<leader>oq` | Normal | Quick switch notes                           |
| `<leader>ob` | Normal | Show backlinks                               |
| `<leader>ol` | Normal | Show all links                               |
| `gf`         | Normal | Follow wiki link                             |
| `<CR>`       | Normal | Smart action (follow link / toggle checkbox) |

---

## Markdown

| Key           | Mode          | Description                             |
| ------------- | ------------- | --------------------------------------- |
| `<leader>mp`  | Normal        | Toggle browser preview                  |
| `<leader>mps` | Normal        | Stop browser preview                    |
| `<leader>mg`  | Normal        | Terminal preview (Glow)                 |
| `<leader>um`  | Normal        | Toggle render-markdown rendering        |
| `<leader>tm`  | Normal        | Toggle table mode                       |
| `<leader>tc`  | Normal        | Cycle checkbox state                    |
| `<C-x>`       | Normal/Visual | Toggle task checkbox (markdown buffers) |
| `]]` / `[[`   | Normal        | Next / prev heading                     |
| `]c`          | Normal        | Go to current heading                   |
| `]p`          | Normal        | Go to parent heading                    |
| `gx`          | Normal        | Follow link                             |
| `gs` / `gss`  | Normal        | Inline surround toggle / line           |
| `ds`          | Normal        | Inline surround delete                  |
| `cs`          | Normal        | Inline surround change                  |
| `gl`          | Normal        | Add link                                |

---

## Completion (blink.cmp — Insert Mode)

| Key                | Description           |
| ------------------ | --------------------- |
| `<C-Space>`        | Show / toggle docs    |
| `<CR>`             | Accept completion     |
| `<Tab>`            | Snippet forward       |
| `<S-Tab>`          | Snippet backward      |
| `<Up>` / `<C-p>`   | Previous item         |
| `<Down>` / `<C-n>` | Next item             |
| `<C-e>`            | Hide menu             |
| `<C-u>` / `<C-d>`  | Scroll docs up / down |

---

## Search & Telescope

| Key           | Mode   | Description                    |
| ------------- | ------ | ------------------------------ |
| `<leader>log` | Normal | Find all `console.log()` calls |

> LazyVim provides: `<leader>ff` find files, `<leader>fg` live grep, `<leader>fb` buffers, `<leader>fh` help

---

## Notifications & UI

| Key          | Mode   | Description                     |
| ------------ | ------ | ------------------------------- |
| `<leader>nn` | Normal | Dismiss all Noice notifications |

---

## Python

| Key          | Mode   | Description                       |
| ------------ | ------ | --------------------------------- |
| `<leader>cv` | Normal | Select Python virtual environment |

---

## Checkbox States (render-markdown)

| Raw   | Rendered | Meaning     |
| ----- | -------- | ----------- |
| `[ ]` | `󰄱`      | Todo        |
| `[x]` | `󰱒`      | Done        |
| `[-]` | `󰥔`      | In progress |
| `[~]` | `󰪥`      | Doing       |
| `[>]` | `󰪠`      | Delegated   |
| `[/]` | `󰰱`      | Cancelled   |
| `[!]` | `󰀪`      | Important   |
| `[?]` | `󰘥`      | Question    |
