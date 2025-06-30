# Yazi File Manager Cheat Sheet

## Basic Navigation
| Key | Action |
|-----|--------|
| `j` / `↓` | Move down |
| `k` / `↑` | Move up |
| `l` / `→` / `Enter` | Enter directory / Open file |
| `h` / `←` | Go to parent directory |
| `g` | Go to top |
| `G` | Go to bottom |
| `Ctrl-u` | Page up |
| `Ctrl-d` | Page down |

## File Operations
| Key | Action |
|-----|--------|
| `o` | Open file |
| `O` | Open file interactively (choose application) |
| `Enter` | Open file with default application |
| `y` | Copy (yank) |
| `x` | Cut |
| `p` | Paste |
| `d` | Delete |
| `D` | Delete permanently (skip trash) |
| `a` | Create new file/directory |
| `r` | Rename |
| `c` | Copy file/directory |
| `m` | Move file/directory |

## Selection
| Key | Action |
|-----|--------|
| `Space` | Toggle selection |
| `v` | Enter visual mode |
| `V` | Enter visual mode (select all) |
| `Ctrl-a` | Select all |
| `Ctrl-r` | Reverse selection |
| `Esc` | Clear selection / Exit mode |

## Search and Filter
| Key | Action |
|-----|--------|
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next search result |
| `N` | Previous search result |
| `f` | Filter files |
| `F` | Smart filter |
| `s` | Sort files |
| `S` | Sort files interactively |

## View and Display
| Key | Action |
|-----|--------|
| `i` | Toggle preview |
| `I` | Toggle preview in full screen |
| `w` | Toggle line wrap in preview |
| `z` | Toggle hidden files |
| `T` | Toggle theme |
| `Ctrl-h` | Toggle help |

## Tabs and Panes
| Key | Action |
|-----|--------|
| `t` | Create new tab |
| `1-9` | Switch to tab 1-9 |
| `[` | Switch to previous tab |
| `]` | Switch to next tab |
| `{` | Swap tab with previous |
| `}` | Swap tab with next |
| `Ctrl-c` | Close current tab |

## Bookmarks and History
| Key | Action |
|-----|--------|
| `'` | Go to bookmark |
| `m` + `[a-z]` | Create bookmark |
| `'` + `[a-z]` | Go to bookmark |
| `b` | Go back in history |
| `f` | Go forward in history |

## Quick Navigation
| Key | Action |
|-----|--------|
| `~` | Go to home directory |
| `/` | Go to root directory |
| `g` + `h` | Go to home |
| `g` + `c` | Go to config directory |
| `g` + `d` | Go to downloads |
| `g` + `D` | Go to desktop |
| `g` + `r` | Go to trash |

## Archive Operations
| Key | Action |
|-----|--------|
| `z` + `a` | Archive selected files |
| `z` + `e` | Extract archive |

## External Commands
| Key | Action |
|-----|--------|
| `:` | Execute command |
| `!` | Execute shell command |
| `Ctrl-z` | Suspend yazi |
| `q` | Quit |
| `Q` | Quit all tabs |

## Plugin System
| Key | Action |
|-----|--------|
| `;` | Enter plugin mode |
| `u` | Update plugins |

## Configuration
| Key | Action |
|-----|--------|
| `Ctrl-,` | Open settings |
| `R` | Reload configuration |

## Tips and Tricks

### Bulk Operations
- Use visual mode (`v`) to select multiple files
- Use `Ctrl-a` to select all files in current directory
- Use `Space` to toggle individual file selection

### Quick File Creation
- Press `a` and end filename with `/` to create a directory
- Press `a` and type filename to create a file

### Search Tips
- Use `/` for forward search, `?` for backward search
- Press `n` and `N` to navigate through search results
- Use `f` for filtering to show only matching files

### Clipboard Integration
- Yazi integrates with system clipboard
- Copied paths can be used in other applications

### Preview Features
- Preview supports many file types including images, PDFs, and code
- Use `i` to toggle preview on/off
- Use `I` for full-screen preview

## Common Workflows

### File Management
1. Navigate with `j/k` or arrow keys
2. Select files with `Space` or visual mode (`v`)
3. Copy (`y`), cut (`x`), or delete (`d`)
4. Navigate to destination and paste (`p`)

### Quick File Access
1. Use bookmarks (`m` + letter to create, `'` + letter to access)
2. Use search (`/`) to quickly find files
3. Use filter (`f`) to narrow down file list

### Multi-tab Workflow
1. Create new tab with `t`
2. Switch between tabs with `1-9` or `[` / `]`
3. Move files between tabs using copy/paste operations

---

*This cheat sheet covers the most commonly used yazi commands. For advanced features and customization, refer to the official yazi documentation.*