-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.swapfile = false

local opt = vim.opt

opt.clipboard = "unnamedplus" -- Sync with system clipboard
opt.conceallevel = 1 -- Hide * markup for bold and italic
opt.inccommand = "nosplit" -- preview incremental substitute
opt.colorcolumn = "100" -- mark column
opt.laststatus = 2 -- Show statusline per buffer

vim.g.lazygit_config = false

vim.g.autoformat = false
