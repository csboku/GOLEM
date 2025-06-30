# Neovim Keybindings Summary

This document outlines the keybindings configured in your Neovim setup.

**Leader Keys:**
* `<leader>` is mapped to `Space`
* `<localleader>` is mapped to `,`

## General Neovim & Window Management

| Mode  | Keybinding       | Action                                             | File                 |
| :---- | :--------------- | :------------------------------------------------- | :------------------- |
| Normal| `<leader>c`      | Clear search highlighting                          | `core/keymaps.lua`  |
| Normal| `<F2>`           | Toggle code paste mode (`:set invpaste paste?`)    | `core/keymaps.lua`  |
| Normal| `<leader>tk`     | Change vertical split to horizontal                | `core/keymaps.lua`  |
| Normal| `<leader>th`     | Change horizontal split to vertical                | `core/keymaps.lua`  |
| Normal| `<C-h>`          | Move to the split left                             | `core/keymaps.lua`  |
| Normal| `<C-j>`          | Move to the split below                            | `core/keymaps.lua`  |
| Normal| `<C-k>`          | Move to the split above                            | `core/keymaps.lua`  |
| Normal| `<C-l>`          | Move to the split right                            | `core/keymaps.lua`  |
| Normal| `<leader>r`      | Reload Neovim configuration (`:so %`)              | `core/keymaps.lua`  |
| Normal| `<leader>s`      | Save current file (`:w`)                           | `core/keymaps.lua`  |
| Normal| `<leader>q`      | Close all windows and exit Neovim (`:qa!`)         | `core/keymaps.lua`  |
| Normal| `<leader>w`      | Close current buffer (`:bd!`)                      | `core/keymaps.lua`  |
| Normal| `<leader>t`      | Go to next tab (`:tabnext`)                        | `core/keymaps.lua`  |
| Normal| `<leader>tt`     | Go to previous tab (`:tabprevious`)                | `core/keymaps.lua`  |
| Normal| `<leader><left>` | Go to previous buffer (`:bprev`)                   | `core/keymaps.lua`  |
| Normal| `<leader><right>`| Go to next buffer (`:bnext`)                     | `core/keymaps.lua`  |
| Normal| `<C-t>`          | Open Terminal (`:Term`)                            | `core/keymaps.lua`  |
| Terminal| `<Esc>`        | Exit Terminal mode (`<C-\><C-n>`)                 | `core/keymaps.lua`  |

*Note: Arrow keys are disabled in Normal mode.*

## Alpha (Dashboard)

| Mode  | Keybinding | Action             | File                    |
| :---- | :--------- | :----------------- | :---------------------- |
| Normal| `e`        | New file           | `plugins/alpha-nvim.lua` |
| Normal| `f`        | Find file (NvimTree) | `plugins/alpha-nvim.lua` |
| Normal| `s`        | Open Settings      | `plugins/alpha-nvim.lua` |
| Normal| `u`        | Update plugins     | `plugins/alpha-nvim.lua` |
| Normal| `r`        | Recent files (Telescope) | `plugins/alpha-nvim.lua` |
| Normal| `q`        | Quit Neovim        | `plugins/alpha-nvim.lua` |

## Telescope

| Mode  | Keybinding | Action            | File                 |
| :---- | :--------- | :---------------- | :------------------- |
| Normal| `<leader>ff` | Find files        | `core/keymaps.lua`  |
| Normal| `<leader>fg` | Live grep         | `core/keymaps.lua`  |
| Normal| `<leader>fb` | List buffers      | `core/keymaps.lua`  |
| Normal| `<leader>fh` | Search help tags  | `core/keymaps.lua`  |

## NvimTree (File Explorer)

| Mode  | Keybinding | Action            | File                 |
| :---- | :--------- | :---------------- | :------------------- |
| Normal| `<C-n>`    | Toggle NvimTree   | `core/keymaps.lua`  |
| Normal| `<leader>nf` | Refresh NvimTree  | `core/keymaps.lua`  |
| Normal| `<leader>nn` | Find file in Tree | `core/keymaps.lua`  |

## Tagbar

| Mode  | Keybinding | Action        | File                 |
| :---- | :--------- | :------------ | :------------------- |
| Normal| `<leader>z` | Toggle Tagbar | `core/keymaps.lua`  |

## Iron (REPL Integration)

| Mode         | Keybinding        | Action                        | File                |
| :----------- | :---------------- | :---------------------------- | :------------------ |
| Normal       | `<localleader>rr` | Toggle REPL window            | `plugins/iron.lua` |
| Normal       | `<localleader>rR` | Restart REPL process          | `plugins/iron.lua` |
| Normal/Visual| `<localleader>sc` | Send motion/visual selection  | `plugins/iron.lua` |
| Normal       | `<localleader>sf` | Send entire file              | `plugins/iron.lua` |
| Normal       | `<localleader>sl` | Send current line             | `plugins/iron.lua` |
| Normal       | `<localleader>sp` | Send current paragraph        | `plugins/iron.lua` |
| Normal       | `<localleader>su` | Send from start of line to cursor | `plugins/iron.lua` |
| Normal       | `<localleader>sm` | Send marked text              | `plugins/iron.lua` |
| Normal       | `<localleader>sb` | Send current code block       | `plugins/iron.lua` |
| Normal       | `<localleader>sn` | Send block and move cursor    | `plugins/iron.lua` |
| Normal/Visual| `<localleader>mc` | Mark motion/visual selection  | `plugins/iron.lua` |
| Normal       | `<localleader>md` | Remove marked text highlight  | `plugins/iron.lua` |
| Normal       | `<localleader>s<cr>`| Send carriage return to REPL | `plugins/iron.lua` |
| Normal       | `<localleader>s<localleader>`| Send interrupt (Ctrl+C) | `plugins/iron.lua` |
| Normal       | `<localleader>sq` | Exit REPL process             | `plugins/iron.lua` |
| Normal       | `<localleader>cl` | Clear REPL screen             | `plugins/iron.lua` |
| Normal       | `<localleader>rf` | Focus REPL                    | `plugins/iron.lua` |
| Normal       | `<localleader>rh` | Hide REPL                     | `plugins/iron.lua` |

## Vimwiki

| Mode  | Keybinding         | Action                           | File                                    |
| :---- | :----------------- | :------------------------------- | :-------------------------------------- |
| Normal| `<leader>ww`       | Open default wiki index file     | `plugins/vimwiki.lua`, `core/lazy.lua` |
| Normal| `<leader>ws`       | Select and open wiki index file  | `plugins/vimwiki.lua`, `core/lazy.lua` |
| Normal| `<leader>wd`       | Open diary index file            | `plugins/vimwiki.lua`, `core/lazy.lua` |
| Normal| `<leader>wn`       | Make a new diary note            | `plugins/vimwiki.lua`, `core/lazy.lua` |
| Normal| `<leader>wt`       | Create a new table               | `core/lazy.lua`                       |
| Normal| `<Leader>w<Leader>t` | Open index in new tab        | `core/lazy.lua`                       |

## LSP (Language Server Protocol) & Diagnostics

| Mode  | Keybinding     | Action                             | File                 |
| :---- | :------------- | :--------------------------------- | :------------------- |
| Normal| `gD`           | Go to Declaration                  | `lsp/lspconfig.lua` |
| Normal| `gd`           | Go to Definition                   | `lsp/lspconfig.lua` |
| Normal| `K`            | Show Hover information             | `lsp/lspconfig.lua` |
| Normal| `gi`           | Go to Implementation               | `lsp/lspconfig.lua` |
| Normal| `<C-k>`        | Show Signature Help                | `lsp/lspconfig.lua` |
| Normal| `<space>wa`    | Add Workspace Folder               | `lsp/lspconfig.lua` |
| Normal| `<space>wr`    | Remove Workspace Folder            | `lsp/lspconfig.lua` |
| Normal| `<space>wl`    | List Workspace Folders             | `lsp/lspconfig.lua` |
| Normal| `<space>D`    | Go to Type Definition              | `lsp/lspconfig.lua` |
| Normal| `<space>rn`    | Rename Symbol                      | `lsp/lspconfig.lua` |
| Normal| `<space>ca`    | Show Code Actions                  | `lsp/lspconfig.lua` |
| Normal| `gr`           | Show References                    | `lsp/lspconfig.lua` |
| Normal| `<space>f`    | Format Code (async)                | `lsp/lspconfig.lua` |
| Normal| `<space>e`    | Show Line Diagnostics (float)      | `lsp/lspconfig.lua` |
| Normal| `[d`           | Go to Previous Diagnostic          | `lsp/lspconfig.lua` |
| Normal| `]d`           | Go to Next Diagnostic              | `lsp/lspconfig.lua` |
| Normal| `<space>q`    | Set Diagnostics Loclist            | `lsp/lspconfig.lua` |

## Neorg

| Mode  | Keybinding         | Action                            | File                 |
| :---- | :----------------- | :-------------------------------- | :------------------- |
| Normal| `<leader>oo`       | Open Neorg index                  | `core/keymaps.lua`  |
| Normal| `<leader>op`       | Open Neorg journal                | `core/keymaps.lua`  |
| Normal| `<localleader>nn`   | Create new Neorg note             | `core/keymaps.lua`  |
| Normal| `gO`               | Show Neorg Table of Contents (TOC)| `core/keymaps.lua`  |
| Normal| `<localleader>tu`   | Set task to undone                | `core/keymaps.lua`  |
| Normal| `<localleader>tp`   | Set task to pending               | `core/keymaps.lua`  |
| Normal| `<localleader>td`   | Set task to done                  | `core/keymaps.lua`  |
| Normal| `<localleader>th`   | Set task to on-hold               | `core/keymaps.lua`  |
| Normal| `<localleader>tc`   | Set task to cancelled             | `core/keymaps.lua`  |
| Normal| `<localleader>tr`   | Set task to recurring             | `core/keymaps.lua`  |
| Normal| `<localleader>ti`   | Set task to important             | `core/keymaps.lua`  |
| Normal| `<localleader>ta`   | Set task to ambiguous             | `core/keymaps.lua`  |
| Normal| `<C-Space>`        | Cycle task status                 | `core/keymaps.lua`  |
| Normal| `<CR>`             | Hop to link                       | `core/keymaps.lua`  |
| Normal| `<M-CR>`           | Hop to link (vertical split)      | `core/keymaps.lua`  |
| Normal| `<M-t>`            | Hop to link (tab drop)            | `core/keymaps.lua`  |
| Normal| `>.`               | Promote heading                   | `core/keymaps.lua`  |
| Normal| `<,`               | Demote heading                    | `core/keymaps.lua`  |
| Normal| `>>`               | Promote heading (nested)          | `core/keymaps.lua`  |
| Normal| `<<`               | Demote heading (nested)           | `core/keymaps.lua`  |
| Normal| `<localleader>lt`   | Toggle list pivot                 | `core/keymaps.lua`  |
| Normal| `<localleader>li`   | Invert list pivot                 | `core/keymaps.lua`  |
| Normal| `<localleader>id`   | Insert date                       | `core/keymaps.lua`  |
| Normal| `<localleader>cm`   | Magnify code block                | `core/keymaps.lua`  |
| Insert| `<C-t>`            | Promote heading                   | `core/keymaps.lua`  |
| Insert| `<C-d>`            | Demote heading                    | `core/keymaps.lua`  |
| Insert| `<M-CR>`           | Next iteration                    | `core/keymaps.lua`  |
| Insert| `<M-d>`            | Insert date                       | `core/keymaps.lua`  |
| Visual| `>`                | Promote heading range             | `core/keymaps.lua`  |
| Visual| `<`                | Demote heading range              | `core/keymaps.lua`  |

## Completion (nvim-cmp & luasnip)

| Mode    | Keybinding | Action                                   | File                  |
| :------ | :--------- | :--------------------------------------- | :-------------------- |
| Insert  | `<C-n>`    | Select next completion item              | `plugins/nvim-cmp.lua` |
| Insert  | `<C-p>`    | Select previous completion item          | `plugins/nvim-cmp.lua` |
| Insert  | `<C-g>`    | Scroll documentation down                | `plugins/nvim-cmp.lua` |
| Insert  | `<C-f>`    | Scroll documentation up                  | `plugins/nvim-cmp.lua` |
| Insert  | `<C-Space>`| Trigger completion                       | `plugins/nvim-cmp.lua` |
| Insert  | `<C-e>`    | Close completion menu                    | `plugins/nvim-cmp.lua` |
| Insert  | `<CR>`     | Confirm selection (Replace)              | `plugins/nvim-cmp.lua` |
| Insert  | `<Tab>`    | Select next item / Expand or Jump snippet | `plugins/nvim-cmp.lua` |
| Insert  | `<S-Tab>`  | Select previous item / Jump snippet back | `plugins/nvim-cmp.lua` |
