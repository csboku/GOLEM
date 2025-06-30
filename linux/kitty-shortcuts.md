# Kitty Terminal Keyboard Shortcuts Cheat Sheet

## Your Configuration
- **Modifier Key (kitty_mod)**: `ctrl+shift`
- **Font**: JetBrains Mono NF (size 11)
- **Theme**: Catppuccin-Mocha
- **Tab Bar Style**: Powerline
- **Enabled Layouts**: tall, fat, grid, horizontal, vertical, stack

---

## Active Custom Shortcuts

### Clipboard Operations
| Shortcut | Action | Notes |
|----------|--------|-------|
| `ctrl+shift+c` | Copy to clipboard | Your configured shortcut |
| `ctrl+shift+v` | Paste from clipboard | Your configured shortcut |

### Window Management  
| Shortcut | Action | Notes |
|----------|--------|-------|
| `ctrl+shift+n` | Next window | Your configured shortcut |

---

## Default Kitty Shortcuts (Still Active)

### Window Management
| Shortcut | Action |
|----------|--------|
| `ctrl+shift+enter` | New window |
| `ctrl+shift+w` | Close window |
| `ctrl+shift+[` | Previous window |
| `ctrl+shift+f` | Move window forward |
| `ctrl+shift+b` | Move window backward |
| `ctrl+shift+`` ` | Move window to top |
| `ctrl+shift+r` | Start resizing window |
| `ctrl+shift+1-9` | Go to window 1-9 |
| `ctrl+shift+0` | Go to window 10 |

### Tab Management
| Shortcut | Action |
|----------|--------|
| `ctrl+shift+t` | New tab |
| `ctrl+shift+q` | Close tab |
| `ctrl+shift+right` | Next tab |
| `ctrl+shift+left` | Previous tab |
| `ctrl+shift+.` | Move tab forward |
| `ctrl+shift+,` | Move tab backward |
| `ctrl+shift+alt+t` | Set tab title |

### Layout Management
| Shortcut | Action | Available Layouts |
|----------|--------|-------------------|
| `ctrl+shift+l` | Next layout | tall, fat, grid, horizontal, vertical, stack |

### Font Size
| Shortcut | Action |
|----------|--------|
| `ctrl+shift+equal` | Increase font size |
| `ctrl+shift+minus` | Decrease font size |
| `ctrl+shift+backspace` | Reset font size |

### Scrolling
| Shortcut | Action |
|----------|--------|
| `ctrl+shift+up` / `ctrl+shift+k` | Scroll line up |
| `ctrl+shift+down` / `ctrl+shift+j` | Scroll line down |
| `ctrl+shift+page_up` | Scroll page up |
| `ctrl+shift+page_down` | Scroll page down |
| `ctrl+shift+home` | Scroll to top |
| `ctrl+shift+end` | Scroll to bottom |
| `ctrl+shift+h` | Show scrollback buffer |

### Hints Mode (Text Selection)
| Shortcut | Action |
|----------|--------|
| `ctrl+shift+e` | Open hints mode (select URLs) |
| `ctrl+shift+p>f` | Select path/filename and insert |
| `ctrl+shift+p>shift+f` | Select path and open |
| `ctrl+shift+p>l` | Select line and insert |
| `ctrl+shift+p>w` | Select word and insert |
| `ctrl+shift+p>h` | Select hash and insert |
| `ctrl+shift+p>n` | Select filename:linenum |
| `ctrl+shift+p>y` | Select hyperlink |

### Miscellaneous
| Shortcut | Action |
|----------|--------|
| `ctrl+shift+f11` | Toggle fullscreen |
| `ctrl+shift+f10` | Toggle maximized |
| `ctrl+shift+u` | Unicode input |
| `ctrl+shift+f2` | Edit config file |
| `ctrl+shift+escape` | Kitty shell |
| `ctrl+shift+delete` | Clear terminal |

### Background Opacity
| Shortcut | Action |
|----------|--------|
| `ctrl+shift+a>m` | Increase opacity +0.1 |
| `ctrl+shift+a>l` | Decrease opacity -0.1 |
| `ctrl+shift+a>1` | Set opacity to 1 |
| `ctrl+shift+a>d` | Set default opacity |

---

## Multi-Key Shortcuts
Some shortcuts require pressing multiple keys in sequence (indicated by `>`):
- Press the first key combination
- Release all keys
- Press the second key combination

Example: `ctrl+shift+p>f` means:
1. Press `ctrl+shift+p`
2. Release all keys
3. Press `f`

---

## Tips from Your Config

1. **Audio Bell**: Disabled (no beeping)
2. **Confirm Window Close**: Set to 0 (no confirmation needed)
3. **Copy on Select**: Not enabled (must use ctrl+shift+c)
4. **Scrollback**: 2000 lines (default)

---

## Creating Custom Shortcuts

Add to your kitty.conf:
```conf
# Example: map a custom shortcut
map ctrl+alt+r launch --cwd=current R
map ctrl+alt+j launch --cwd=current julia
map ctrl+alt+p launch --cwd=current python3
```

## Useful Commands

- List all fonts: `kitty + list-fonts`
- Debug keyboard: `kitty --debug-keyboard`
- Remote control: `kitty @ [command]`

---

*Note: This cheat sheet is based on your kitty.conf configuration. Commented-out mappings use default bindings.*