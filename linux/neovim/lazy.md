# Neovim Plugin Configuration

This directory (`~/.config/nvim/lua/plugins/`) contains the configuration for Neovim plugins managed by `lazy.nvim`.

## Structure

`lazy.nvim` automatically loads all `.lua` files from this directory. Each file should define and configure one or more plugins.

There are two main patterns used here:

### 1. Full Plugin Specification (Recommended)

This is the standard `lazy.nvim` approach. The file returns a Lua table containing the plugin's repository, dependencies, and configuration. This keeps each plugin's setup self-contained.

**Example (`codecompanion.nvim.lua`):**
```lua
return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  opts = {
    -- Plugin options go here
  },
}
```

### 2. Configuration-Only File

Some files in this directory might only contain a `setup()` call for a plugin. This implies the plugin itself is defined and loaded in a different part of the Neovim configuration, and these files are solely for organization.

**Example (`alpha-nvim.lua`):**
```lua
local status_ok, alpha = pcall(require, 'alpha')
if not status_ok then
  return
end

alpha.setup(dashboard.config)
```

## Managing Plugins

*   **Add a Plugin:** Create a new `.lua` file in this directory that returns the plugin's specification table.
*   **Disable a Plugin:** In the plugin's specification table, add the line `enabled = false`.
    ```lua
    return {
      'some/plugin',
      enabled = false, -- This plugin will not be loaded
    }
    ```
*   **Configure a Plugin:** Modify the `opts` table or the `config` function within the plugin's specification.
