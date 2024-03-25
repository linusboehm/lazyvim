-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.swapfile = false

local opt = vim.opt

opt.clipboard = "unnamedplus" -- Sync with system clipboard
opt.conceallevel = 0 -- Hide * markup for bold and italic
opt.inccommand = "nosplit" -- preview incremental substitute

vim.g.autoformat = false

-- avoid "write partial file message" when saving in visual mode
vim.cmd("cabbrev <expr> w getcmdtype()==':' && getcmdline() == \"'<,'>w\" ? '<c-u>w' : 'w'")
