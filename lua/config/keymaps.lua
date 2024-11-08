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

map("n", "gL", function()
  local c_row, c_column = unpack(vim.api.nvim_win_get_cursor(0))
  local filename = vim.fn.expand("<cfile>")
  local line_nr_pattern = ":[0-9]"
  local match_line_nr = vim.fn.search(filename .. line_nr_pattern, "e")
  local line_nr = vim.fn.expand("<cword>")
  -- move cursor back to orig position
  vim.api.nvim_win_set_cursor(0, { c_row, c_column })
  -- go to left most buffer
  vim.api.nvim_command([[wincmd 100h]])
  if match_line_nr == c_row then
    misc_util.open_file_at_location(filename, line_nr, 1)
  else
    misc_util.open_file(filename)
  end
end, { desc = "go to file in other window" })

map("n", "gl", function()
  local c_row, c_column = unpack(vim.api.nvim_win_get_cursor(0))
  local filename = vim.fn.expand("<cfile>")
  local line_nr_pattern = ":[0-9]"
  local match_line_nr = vim.fn.search(filename .. line_nr_pattern, "e")
  local line_nr = vim.fn.expand("<cword>")
  -- move cursor back to orig position
  vim.api.nvim_win_set_cursor(0, { c_row, c_column })
  -- go to left most buffer
  vim.cmd("e" .. filename)
  if match_line_nr == c_row then
    vim.api.nvim_win_set_cursor(0, { tonumber(line_nr), 0 })
  end
end, { desc = "go to file" })

-- -- Visual Block --
-- -- Move text up and down
-- map("x", "J", ":move '>+1<CR>gv-gv", { desc = "move text up" })
-- map("x", "K", ":move '<-2<CR>gv-gv", { desc = "move text down" })

-- map("n", "<leader>b1", "<cmd>bfirst<cr>", { desc = "go to first buffer" })
-- map("n", "<leader>b1", "<cmd>bfirst<cr>", { desc = "go to first buffer" })
map("n", "<leader>b1", [[<cmd>lua require("bufferline").go_to_buffer(1, true)<cr>]], { desc = "go to first buffer" })
map("n", "<leader>b2", [[<cmd>lua require("bufferline").go_to_buffer(2, true)<cr>]], { desc = "go to first buffer" })
map("n", "<leader>b3", [[<cmd>lua require("bufferline").go_to_buffer(3, true)<cr>]], { desc = "go to first buffer" })
map("n", "<leader>b4", [[<cmd>lua require("bufferline").go_to_buffer(4, true)<cr>]], { desc = "go to first buffer" })
map("n", "<leader>b5", [[<cmd>lua require("bufferline").go_to_buffer(5, true)<cr>]], { desc = "go to first buffer" })
map("n", "<leader>b6", [[<cmd>lua require("bufferline").go_to_buffer(6, true)<cr>]], { desc = "go to first buffer" })
map("n", "<leader>b7", [[<cmd>lua require("bufferline").go_to_buffer(7, true)<cr>]], { desc = "go to first buffer" })
map("n", "<leader>b8", [[<cmd>lua require("bufferline").go_to_buffer(8, true)<cr>]], { desc = "go to first buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

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
-- vim.keymap.del("n", "<leader>ww") -- , "<C-W>p", { desc = "Other window" })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete window" })
-- vim.keymap.del("n", "<leader>w-") -- , "<C-W>s"), { desc = "Split window below" })
-- vim.keymap.del("n", "<leader>w|") -- , "<C-W>v"), { desc = "Split window right" })
map("n", "<leader>ws", "<C-W>x", { desc = "Switch/x-change windows" })
map("n", "<leader>-", "<C-W>s", { desc = "Split window below" })
map("n", "<leader>|", "<C-W>v", { desc = "Split window right" })
-- map({ "n", "v", "c" }, "<C-I>", "<C-W>|<C-W>_", { desc = "Focus window" })
map({ "n", "v", "i", "t" }, "<C-P>", function()
  local current_height = vim.api.nvim_win_get_height(0)
  local current_width = vim.api.nvim_win_get_width(0)
  local max_height = vim.api.nvim_get_option_value("lines", {})
  local max_width = vim.api.nvim_get_option_value("columns", {})

  local minimize = function()
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
-- vim.keymap.del("t", "<C-k>")
map("n", "<C-k>", function()
  vim.api.nvim_command([[wincmd k]])
  misc_util.go_to_text_buffer()
end, { desc = "Go to upper window" })
map("t", "<C-K>", function()
  vim.api.nvim_command()
  misc_util.go_to_text_buffer()
end, { desc = "Go to upper window" })

-- avoid "write partial file message" when saving in visual mode
map("c", "w", [[getcmdline() =~ "'<,'>" ? '<c-u>w' : 'w']], { expr = true, noremap = true })

vim.api.nvim_command("iabbrev ltodo TODO(lboehm):")
vim.api.nvim_command("iabbrev lnote NOTE(lboehm):")
vim.api.nvim_command('iabbrev <expr>dd strftime("%e-%b-%Y")')
vim.api.nvim_command('iabbrev <expr>tt strftime("%H:%M")')
vim.api.nvim_command('iabbrev <expr>dt strftime("%e-%b-%Y %H:%M")')

local function select_multiline_comment(outer)
  local parser = vim.treesitter.get_parser(0)
  local tree = parser:parse()[1]
  local root = tree:root()

  local cursor_row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  cursor_row = cursor_row - 1

  local query = vim.treesitter.query.parse(
    vim.bo.filetype,
    [[
      [
        (comment) @comment
      ]
    ]]
  )

  local start_row, start_col, end_row, end_col
  for _, node in query:iter_captures(root, 0, cursor_row, cursor_row + 1) do
    local s_row, s_col, e_row, e_col = vim.treesitter.get_node_range(node)
    if s_row <= cursor_row and e_row >= cursor_row then
      start_row, start_col = s_row, s_col
      end_row, end_col = e_row, e_col
      break
    end
  end

  local comm_string = vim.api.nvim_buf_get_option(0, "commentstring"):match("([^%s]*)"):gsub("%W", "%%%1")

  if start_row and end_row then
    -- Extend the selection upwards to include adjacent single-line comments
    local new_start_row, new_start_col = start_row, start_col
    while true do
      local prev_row = new_start_row - 1
      local prev_line = vim.fn.getline(prev_row + 1)
      if not prev_line:match("^%s*" .. comm_string) then
        break
      end
      new_start_row = prev_row
      new_start_col = 0
    end

    -- Extend the selection downwards to include adjacent single-line comments
    local new_end_row, new_end_col = end_row, end_col
    while true do
      local next_row = new_end_row + 1
      local next_line = vim.fn.getline(next_row + 1)
      if not next_line:match("^%s*" .. comm_string) then
        break
      end
      new_end_row = next_row
      new_end_col = #next_line
    end

    if outer then
      -- delete consecutive empty lines
      local prev_line = vim.fn.getline(new_start_row)
      local next_line = vim.fn.getline(new_end_row + 2)
      if prev_line == "" and next_line == "" then
        new_start_row = new_start_row - 1
        new_start_col = 0
      end
    end

    vim.fn.setpos("'<", { 0, new_start_row + 1, new_start_col + 1, 0 })
    vim.fn.setpos("'>", { 0, new_end_row + 1, new_end_col + 1, 0 })
    vim.cmd("normal! gv")
  end
end

local function select_multiline_comment_inner()
  select_multiline_comment(false)
end
local function select_multiline_comment_outer()
  select_multiline_comment(true)
end

map("x", "iC", select_multiline_comment_inner, { desc = "comment", noremap = true, silent = true })
map("o", "iC", select_multiline_comment_inner, { desc = "comment", noremap = true, silent = true })
map("x", "aC", select_multiline_comment_outer, { desc = "comment", noremap = true, silent = true })
map("o", "aC", select_multiline_comment_outer, { desc = "comment", noremap = true, silent = true })

map("n", "<leader>ce", function()
  misc_util.dump_color_codes()
end, { desc = "write code to file" })

vim.cmd("command! ExportTSSyntax lua export_treesitter_syntax()")
