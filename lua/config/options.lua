-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.swapfile = false

local opt = vim.opt

if vim.env.ZELLIJ and not vim.env.TMUX and not vim.env.DISPLAY and not vim.env.WAYLAND_DISPLAY then
  local cache = {}
  local function copy(reg)
    return function(lines, regtype)
      cache[reg] = { lines, regtype }
      require("vim.ui.clipboard.osc52").copy(reg)(lines, regtype)
    end
  end
  local function paste(reg)
    return function()
      return cache[reg] or cache["+"] or cache["*"] or { {}, "v" }
    end
  end

  vim.g.clipboard = {
    name = "OSC 52 copy-only",
    copy = {
      ["+"] = copy("+"),
      ["*"] = copy("*"),
    },
    paste = {
      ["+"] = paste("+"),
      ["*"] = paste("*"),
    },
  }
end

opt.clipboard = "unnamedplus" -- Sync with system clipboard
opt.conceallevel = 1 -- Hide * markup for bold and italic
opt.inccommand = "nosplit" -- preview incremental substitute
opt.colorcolumn = "100" -- mark column
opt.laststatus = 2 -- Show statusline per buffer
opt.spell = true -- Enable spell checking by default
opt.signcolumn = "auto" -- Only show the sign gutter when signs are present
opt.numberwidth = 2 -- Keep the line-number gutter compact

vim.g.lazygit_config = false

vim.g.autoformat = false

vim.g.lazyvim_picker = "snacks"
