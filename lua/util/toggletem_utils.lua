local M = {}

local misc_util = require("util.misc")
local CoreUtil = require("lazy.core.util")

local function run_cmd(cmd)
  local keys = [[<esc>i<C-e><C-u>]] .. cmd .. [[<CR>]]
  local key = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(key, "n", false)
end

local function go_to_terminal_and_run(cmd)
  for var = 1, 5 do
    -- term://~/repos/trading_platform/scripts//28571:/bin/bash;#toggleterm#1
    -- if string.find(vim.fn.expand("%"), "/bin/bash;#toggleterm") then
    if vim.bo.filetype == "snacks_terminal" then
      run_cmd(cmd)
      return true
    end
    vim.api.nvim_command([[wincmd j]])
  end
  return false
end

function M.run_in_terminal(cmd)
  local curr_win = vim.api.nvim_get_current_win()
  local buf_nr = vim.api.nvim_get_current_buf()
  -- save only if modified (don't change last saved timestamp before rebuild)
  if vim.bo[buf_nr].modified == true then
    vim.api.nvim_command([[w]])
  end
  if not go_to_terminal_and_run(cmd) then
    -- didn't find terminal -> toggle to open
    Snacks.terminal()
    go_to_terminal_and_run(cmd)
  end
  vim.schedule(function()
    vim.api.nvim_set_current_win(curr_win)
  end)
end

-- HELPER FUNCTIONS
local open_cpp_file = function()
  local filename = vim.fn.findfile(vim.fn.expand("<cfile>"), "**")
  -- get line_nr
  vim.fn.search(filename .. ":[0-9]", "e")
  local line_nr = vim.fn.expand("<cword>")
  -- get col_nr
  vim.fn.search(":[0-9]", "e")
  local col_nr = vim.fn.expand("<cword>")
  -- move cursor back to beginning of row
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_win_set_cursor(0, { row, 0 })

  misc_util.open_file_at_location(filename, line_nr, col_nr)
end

local open_python_file = function(line)

  local _, _, path, line_nr = string.find(line, '"([^"]*)".*line (%d+)')
  CoreUtil.info("trying to open: " .. path .. ":" .. line_nr, { title = "filename" })
  misc_util.open_file_at_location(path, line_nr, 1)

  -- local Util = require("lazyvim.util")
  -- Util.telescope("find_files", {
  --   default_text = default_text,
  --   cwd = git_root,
  --   on_complete = {
  --     function(picker)
  --       require("telescope.actions").select_default(picker.prompt_bufnr)
  --     end,
  --   },
  -- })()
end

local function get_curr_search_match()
  -- save current cursor position
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_feedkeys('gn"ly', "x", false)
  local selection = vim.fn.getreg("l")
  selection = string.gsub(selection, "[\n\r]", "")
  -- reset cursor position
  vim.api.nvim_win_set_cursor(0, { row, col })
  return selection
end

local open_file = function()
  -- local key = vim.api.nvim_replace_termcodes(search_cmd, true, false, true)
  -- vim.api.nvim_feedkeys(key, 'n', false)
  -- local l = vim.api.nvim_get_current_line()
  local l = get_curr_search_match()
  if string.find(l, [[.py]]) then
    open_python_file(l)
  else
    open_cpp_file()
  end
end

-- SEARCH THROUGH CPP COMPILER OUTPUT/PYTHON ERRORS
local user = os.getenv("USER")
-- local hostname = tostring(os.getenv("HOSTNAME"))
-- local host = string.sub(hostname, string.find(hostname, "%."))
local cmd_line = user .. "@"
local cpp_line = [[^.*\.[cph]\+:[0-9]\+:[0-9]\+:\|\/home\/.*\.[cpph]\+:[0-9]\+:]]
local python_line = [[^[ ]\+File "[^"]*\n\?.*".*]]
local file = cpp_line .. [[\|]] .. python_line
local search_cmd = "<cmd>set nowrapscan<CR>G?.<CR>k?"
  .. cmd_line
  .. [[<CR><cmd>silent!/]]
  .. file
  .. [[<CR><cmd>set wrapscan<CR>]]

-- OPEN C++/PYTHON on ERROR
function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
  vim.keymap.set("t", "jj", [[<C-\><C-n>]], opts)
  vim.keymap.set("t", "kk", [[<C-u><C-\><C-n>]], opts)
  vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
  -- need to enter normal mode before command and re-enter interactive mode after:
  vim.keymap.set("t", "<C-z>", [[<C-\><C-n><Cmd>ZenMode<CR>i]])

  vim.keymap.set("t", "<C-f>", [[<C-\><C-n>]] .. search_cmd, opts)
  vim.keymap.set("n", "<C-f>", search_cmd, opts)
  vim.keymap.set("n", "gf", open_file, opts)
end

-- vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*bash",
  callback = function(ev)
    Snacks.notify("Terminal opened!")
    -- local cwd = vim.fn.getcwd()
    -- vim.api.nvim_chan_send(ev.buf, "cd " .. cwd .. "\n")
    set_terminal_keymaps()
  end,
})


return M
