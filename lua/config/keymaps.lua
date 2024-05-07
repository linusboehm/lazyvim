-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local misc_util = require("util.misc")
local CoreUtil = require("lazy.core.util")

-- from vim
map("i", "jj", "<esc>", { desc = "exit insert mode" })

-- yank from the cursor to the end of the line, to be consistent with C and D
map("n", "vv", "V")
map("n", "V", "v$")

-- go to end
map("n", "E", "$")

-- Resize window using <ctrl> arrow keys
vim.keymap.del("n", "<C-Up>")
vim.keymap.del("n", "<C-Down>")
vim.keymap.del("n", "<C-Left>")
vim.keymap.del("n", "<C-Right>")

map({ "n", "v", "i", "t" }, "<C-Up>", "<cmd>resize +10<cr>", { desc = "Increase window height" })
map({ "n", "v", "i", "t" }, "<C-Down>", "<cmd>resize -10<cr>", { desc = "Decrease window height" })
map({ "n", "v", "i", "t" }, "<C-Left>", "<cmd>vertical resize -10<cr>", { desc = "Decrease window width" })
map({ "n", "v", "i", "t" }, "<C-Right>", "<cmd>vertical resize +10<cr>", { desc = "Increase window width" })

-- -- Move Lines
-- map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
-- map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
-- map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
-- map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
-- map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
-- map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- map("n", "<leader>gyu", function()
--   -- test something here
--   vim.print("hello")
-- end, { desc = "test something" })

-- printing
-- map("n", "<leader>pf", ":m '<-2<cr>gv=gv", { desc = "Move up" })
map("n", "<leader>pf", function()
  local path = vim.api.nvim_buf_get_name(0)
  local git_root = misc_util.get_git_root()
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.fn.setreg("+", path .. ":" .. row)
  path = path:gsub(git_root .. "/", "")
  CoreUtil.info(path, { title = "current file name" })
end, { desc = "print current filename" })

-- -- Visual Block --
-- -- Move text up and down
-- map("x", "J", ":move '>+1<CR>gv-gv", { desc = "move text up" })
-- map("x", "K", ":move '<-2<CR>gv-gv", { desc = "move text down" })

map("n", "<leader>b1", "<cmd>bfirst<cr>", { desc = "go to firs buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
-- map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

map("n", "*", "*Nzz")
--
-- fix sloppy saving
map({ "i" }, "j;w", "<cmd>w<cr><esc>", { desc = "Save file" })
map({ "i" }, "j;jw", "<cmd>w<cr><esc>", { desc = "Save file" })
-- -- map({ "i", "v", "n", "s" }, ";w<CR>", "<cmd>w<cr><esc>", { desc = "Save file" })
-- -- map("i", "jjw", "<esc>:w<CR>", { desc = "Save file" })
-- -- map("n", "<Leader>bw", "<esc>:w<CR>", { desc = "Save file" })

-- remap colon to semicolon in norman and visual mode, but not in insert mode
map("n", ";", ":", { desc = "semicolon -> colon", noremap = true, silent = false })
map("n", ":", ";", { desc = "colon -> semicolon", noremap = true, silent = false })
map("v", ";", ":", { desc = "semicolon -> colon", noremap = true, silent = false })
map("v", ":", ";", { desc = "colon -> semicolon", noremap = true, silent = false })

-- new file
vim.keymap.del("n", "<leader>fn")
-- toggle floating terminal
vim.keymap.del("n", "<leader>ft")
vim.keymap.del("n", "<leader>fT")
vim.keymap.del("n", "<C-f>")
vim.keymap.del("n", "<C-b>")
vim.keymap.del("n", ",")

-- Clear search
map({ "n" }, "<leader>,", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- do not use the default "better" indenting.. it prevents dot-repleat indents
vim.keymap.del("v", ">")
vim.keymap.del("v", "<")

-- windows
vim.keymap.del("n", "<leader>ww") -- , "<C-W>p", { desc = "Other window" })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete window" })
vim.keymap.del("n", "<leader>w-") -- , "<C-W>s"), { desc = "Split window below" })
vim.keymap.del("n", "<leader>w|") -- , "<C-W>v"), { desc = "Split window right" })
map("n", "<leader>ws", "<C-W>x", { desc = "Switch/x-change windows" })
map("n", "<leader>-", "<C-W>s", { desc = "Split window below" })
map("n", "<leader>|", "<C-W>v", { desc = "Split window right" })
-- map({ "n", "v", "c" }, "<C-I>", "<C-W>|<C-W>_", { desc = "Focus window" })
map({ "n", "v", "i", "t" }, "<C-P>", function()
  local current_height = vim.api.nvim_win_get_height(0)
  local current_width = vim.api.nvim_win_get_width(0)
  local max_height = vim.api.nvim_get_option("lines")
  local max_width = vim.api.nvim_get_option("columns")

  local minimize = function ()
    vim.cmd("wincmd =")
    if vim.bo.filetype == "toggleterm" then
      vim.api.nvim_win_set_height(0, 12)
    else
      local new_height = current_height - 12
      vim.api.nvim_win_set_height(0, new_height)
    end
  end

  if current_height > max_height - 20 and current_width > max_width - 20 then
    minimize()
  else
    vim.cmd("wincmd |")
    vim.cmd("wincmd _")
  end
end, { desc = "Toggle window focus" })

-- git-worktree
-- stylua: ignore
map( "n", "<Leader>gw", "<CMD>lua require('telescope').extensions.git_worktree.git_worktrees()<CR>", { desc = "git worktree" })

vim.keymap.del("n", "<C-k>")
vim.keymap.del("t", "<C-k>")
map("n", "<C-k>", function()
  vim.api.nvim_command([[wincmd k]])
  misc_util.go_to_text_buffer()
end, { desc = "Go to upper window" })
map("t", "<C-K>", function()
  vim.api.nvim_command()
  misc_util.go_to_text_buffer()
end, { desc = "Go to upper window" })

-- avoid "write partial file message" when saving in visual mode
map('c', 'w', [[getcmdline() =~ "'<,'>" ? '<c-u>w' : 'w']], {expr = true, noremap = true})

vim.api.nvim_command('iabbrev ltodo TODO(lboehm):')
vim.api.nvim_command('iabbrev lnote NOTE(lboehm):')
