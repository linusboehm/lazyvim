-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "checkhealth",
    "gitsigns-blame",
    "grug-far",
    "help",
    "lspinfo",
    "man",
    "notify",
    "oil",
    "qf",
    "spectre_panel",
    "startuptime",
    "tsplayground",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- change comment style for *.c, *.cpp, *.h files from /*...*/ to // ...
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("set_slash_comment_style"),
  pattern = { "h", "cpp", "c", "proto" },
  callback = function()
    vim.opt_local.commentstring = "// %s"
    -- vim.opt.shiftwidth = 2 -- Size of an indent
    -- vim.opt.tabstop = 2 -- Number of spaces tabs count for
  end,
})

vim.filetype.add({
  extension = {
    coby = "coby",
  },
})

-- Create an augroup for CobyCommentString
local coby_comment_augroup = vim.api.nvim_create_augroup("CobyCommentString", { clear = true })

-- Create an autocmd for setting the commentstring for *.coby files
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.coby",
  command = "setlocal commentstring=//\\ %s",
  group = coby_comment_augroup,
})

-- add current git repo to search path
vim.api.nvim_create_autocmd({ "BufEnter" }, {
  group = augroup("gitroot"),
  callback = function()
    local misc_util = require("util.misc")
    local git_root = misc_util.get_git_root()
    if git_root ~= "/" then
      local path = vim.o.path
      if not string.find(path, git_root, 1, true) then
        vim.o.path = path .. "," .. git_root .. "/"
      end
    end
  end,
})

-- -- enable syntax highlighting for log files
-- vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
--   group = augroup("set_syntax"),
--   pattern = "*.log",
--   command = "set syntax=log",
-- })

-- -- 2 spaces indent for lua
-- vim.api.nvim_create_autocmd("FileType", {
--   group = augroup("lua_indent"),
--   pattern = { "lua", "proto" },
--   callback = function()
--     vim.opt_local.shiftwidth = 2
--     vim.opt_local.tabstop = 2
--   end,
-- })

-- -- wrap and check for spell in text filetypes
-- vim.api.nvim_create_autocmd("FileType", {
--   group = augroup("wrap_spell"),
--   pattern = { "gitcommit", "markdown" },
--   callback = function()
--     vim.opt_local.wrap = true
--     vim.opt_local.spell = true
--   end,
-- })

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "sql",
  },
  command = [[setlocal omnifunc=vim_dadbod_completion#omni]],
})

-- enable syntax highlighting for CMake files
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup("set_filetype"),
  pattern = "*CMake*.txt",
  command = "setfiletype cmake",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("markdown_checkbox"),
  pattern = "markdown",
  callback = function()
    local opts = { buffer = 0 }
    vim.keymap.set({ "n", "v" }, "<leader>cb", function()
      require("util.toggle_checkbox").toggle()
    end, opts)
  end,
})
