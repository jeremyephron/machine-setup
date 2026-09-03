vim.g.mapleader = ","
vim.g.maplocalleader = "\\"

-- This configuration uses native Lua plugins and LSP clients, not Neovim's
-- optional remote-plugin hosts.
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

require("machine_setup.options")
require("machine_setup.keymaps")
require("machine_setup.autocmds")
require("machine_setup.lazy")
