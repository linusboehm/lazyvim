-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set
local misc_util = require("util.misc")
local Snacks = require("snacks")

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

-- TESTS
map({ "n" }, "<leader>ds", require("util.custom_functions").dict_to_squiggle_py, { desc = "dict to squiggle" })
map({ "n" }, "<leader>op", require("util.custom_functions").open_prod)

map({ "n" }, "<leader>tr", require("util.custom_functions").build_and_run, { desc = "build and run current file" })
map({ "n" }, "<leader>tn", require("util.custom_functions").goto_next_slide, { desc = "go to next slide" })

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
  local git_root = Snacks.git.get_root()
  local short_path
  if git_root then
    -- Escape special characters in the leading substring
    local escaped_git_root = git_root:gsub("([%-%.%+%[%]%(%)%$%^%%%?%*])", "%%%1")
    Snacks.notify.info(git_root)
    short_path = path:gsub(escaped_git_root .. "/", "")
  else
    short_path = path
  end
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.fn.setreg("+", short_path .. ":" .. row)
  Snacks.notify.info(short_path .. ":" .. row, { title = "current file name" })
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
    misc_util.open_file(filename, line_nr, 1)
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
  if match_line_nr == c_row then
    misc_util.open_file(filename, line_nr, 1)
  else
    misc_util.open_file(filename)
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
-- vim.keymap.del("n", ",")

-- Clear search
-- map({ "n" }, "<leader>,", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

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
map("n", "<Leader>rb", function()
  local lazy = require("bufferline.lazy")
  local state = lazy.require("bufferline.state") ---@module "bufferline.state"
  local elements = state.components
  local function path_formatter(path)
    return vim.fn.fnamemodify(path, ":p:.")
  end
  local formatted_list = {}
  for _, name in ipairs(elements) do
    table.insert(formatted_list, path_formatter(name.path))
  end
  local joined_string = table.concat(formatted_list, " ")
  require("grug-far").open({ prefills = { paths = joined_string } })
end, { desc = "replace in buffers" })

map("n", "<Leader>bc", function()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_win_get_buf(current_win)
  local current_ft = vim.api.nvim_get_option_value("filetype", { buf = current_buf })

  local wins = vim.api.nvim_tabpage_list_wins(0)

  -- Find the first window (other than current) with the same filetype
  local target_win
  for _, w in ipairs(wins) do
    if w ~= current_win then
      local buf = vim.api.nvim_win_get_buf(w)
      local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
      if ft == current_ft then
        target_win = w
        break
      end
    end
  end

  if not target_win then
    vim.notify("No other window with the same filetype found.", vim.log.levels.WARN)
    return
  end

  -- Check if currently in diff mode
  local current_diff = vim.api.nvim_get_option_value("diff", { win = current_win })
  local target_diff = vim.api.nvim_get_option_value("diff", { win = target_win })
  local already_diffed = current_diff or target_diff

  if already_diffed then
    -- If already diffed, turn off diff mode for all windows
    vim.cmd("diffoff!")
  else
    -- If not diffed yet, run :diffthis in both
    for _, w in ipairs({ current_win, target_win }) do
      vim.api.nvim_set_current_win(w)
      vim.cmd("diffthis")
    end
  end

  -- Restore the originally active window
  vim.api.nvim_set_current_win(current_win)
end, { desc = "diff buffers" })

vim.keymap.del("n", "<C-k>")
-- vim.keymap.del("t", "<C-k>")
map("n", "<C-k>", function()
  vim.api.nvim_command([[wincmd k]])
  misc_util.go_to_text_buffer()
end, { desc = "Go to upper window" })

-- avoid "write partial file message" when saving in visual mode
map("c", "w", [[getcmdline() =~ "'<,'>" ? '<c-u>w' : 'w']], { expr = true, noremap = true })

vim.api.nvim_command("iabbrev ltodo TODO(lboehm):")
vim.api.nvim_command("iabbrev lnote NOTE(lboehm):")
vim.api.nvim_command('iabbrev <expr>dd strftime("%e-%b-%Y")')
vim.api.nvim_command('iabbrev <expr>tt strftime("%H:%M")')
vim.api.nvim_command('iabbrev <expr>dt strftime("%e-%b-%Y %H:%M")')

map("n", "<leader>ce", function()
  misc_util.dump_color_codes()
end, { desc = "write code to file" })

-- vim.cmd("command! ExportTSSyntax lua export_treesitter_syntax()")
