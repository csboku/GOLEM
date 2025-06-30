# Yazi File Manager Cheat Sheet

## Basic Navigation
- `h` / `←` - Go to parent directory
- `j` / `↓` - Move cursor down (next file)
- `k` / `↑` - Move cursor up (previous file)
- `l` / `→` / `Enter` - Enter directory/open file
- `H` - Move to top of screen
- `M` - Move to middle of screen
- `L` - Move to bottom of screen
- `g` `g` - Go to top of list
- `G` - Go to bottom of list

## File Operations
- `<Space>` - Toggle selection of current file
- `v` - Enter visual mode (selection mode)
- `V` - Select all files in directory
- `<Ctrl-a>` - Select all
- `<Ctrl-r>` - Inverse selection
- `<Esc>` - Exit visual mode/clear selection

## Copy/Cut/Paste
- `y` - Yank (copy) selected files
- `x` - Cut selected files
- `p` - Paste yanked files
- `P` - Paste yanked files (overwrite if exists)
- `X` - Cancel cut

## Delete/Create
- `d` - Delete selected files (to trash)
- `D` - Delete selected files permanently
- `a` - Create file/directory (end with `/` for directory)
- `r` - Rename file (bulk rename if multiple selected)

## Search & Filter
- `/` - Search forward
- `?` - Search backward
- `n` - Next search match
- `N` - Previous search match
- `f` - Filter files
- `<Ctrl-s>` - Cancel search

## Directory Navigation
- `.` - Toggle hidden files
- `g` `h` - Go to home directory (~)
- `g` `c` - Go to config directory
- `g` `d` - Go to downloads directory
- `g` `t` - Go to temporary directory (/tmp)
- `g` `<Space>` - Go to directory interactively
- `-` - Go to previous directory
- `=` - Go to next directory

## Tabs
- `t` - Create new tab
- `1`-`9` - Switch to tab number
- `[` - Switch to previous tab
- `]` - Switch to next tab
- `{` - Swap current tab with previous
- `}` - Swap current tab with next

## Opening Files
- `o` - Open file
- `O` - Open file interactively (choose program)
- `<Enter>` - Open file/enter directory

## View & Display
- `~` / `<F1>` - Show help
- `w` - Show task manager
- `i` - Show file info in preview
- `s` - Sort options
- `<Tab>` - Toggle/focus preview pane

## Shell & Commands
- `:` - Run command
- `;` - Run shell command
- `!` - Run shell command (block)
- `&` - Run shell command (background)

## Copy Paths
- `c` `c` - Copy file path
- `c` `d` - Copy directory path
- `c` `f` - Copy filename
- `c` `n` - Copy filename without extension

## Advanced
- `z` `h` - Toggle hidden files (same as `.`)
- `z` `a` - Toggle all files including .git
- `<Ctrl-c>` - Cancel/close tab
- `q` - Quit yazi
- `Q` - Quit without changing directory
- `<Ctrl-z>` - Suspend yazi

## Mouse Support
- Left click - Select file
- Right click - Enter directory
- Scroll - Navigate files

## Tips
- Press `~` or `<F1>` to see all keybindings with descriptions
- Use `/` in help menu to search for commands
- Visual mode (`v`) works like vim for selecting ranges
- Keybindings can be customized in `~/.config/yazi/keymap.toml`