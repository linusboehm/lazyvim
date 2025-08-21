local M = {}

local misc_util = require("util.misc")

local function run_cmd(cmd)
  local keys = [[<esc>i<C-e><C-u>]] .. cmd .. [[<CR>]]
  local key = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_input(key)
end

local function find_window_with_filetype(filetype)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_option(buf, "filetype") == filetype then
      return win
    end
  end
  return nil
end

local function call_in_terminal(cb)
  local term_win = find_window_with_filetype("snacks_terminal")
  if not term_win then
    Snacks.terminal()
    term_win = find_window_with_filetype("snacks_terminal")
  end
  if not term_win then
    Snacks.notify.error("Failed to open terminal")
    return
  end
  vim.api.nvim_set_current_win(term_win)
  cb()
end

function M.run_in_terminal(cmd)
  local curr_win = vim.api.nvim_get_current_win()
  local buf_nr = vim.api.nvim_get_current_buf()
  -- save only if modified (don't change last saved timestamp before rebuild)
  if vim.bo[buf_nr].modified == true then
    vim.api.nvim_command([[w]])
  end
  local cb = function()
    run_cmd(cmd)
  end
  call_in_terminal(cb)
  vim.schedule(function()
    vim.api.nvim_set_current_win(curr_win)
  end)
end

-- HELPER FUNCTIONS
local function open_file_under_cursor()
  local filename = vim.fn.expand("<cfile>")
  -- Define the pattern to search for
  local pattern = filename .. [[:(\d*):(\d*)]]

  -- Search for the pattern under the cursor
  vim.fn.search(pattern, "c")

  -- Get the current line and extract the match
  local line = vim.api.nvim_get_current_line()
  local line_nr, col_nr = line:match(filename:gsub("[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") .. ":(%d*):(%d*)")
  line_nr = line_nr ~= "" and line_nr or nil
  col_nr = col_nr ~= "" and col_nr or "2"

  misc_util.open_file(filename, line_nr, col_nr)
end

-- SEARCH THROUGH CPP COMPILER OUTPUT/PYTHON ERRORS
local user = os.getenv("USER")
-- local hostname = tostring(os.getenv("HOSTNAME"))
-- local host = string.sub(hostname, string.find(hostname, "%."))
local cmd_line = user .. "@"
local username = os.getenv("USER")
local cpp_line = [[^.*\.[cph]\+:[0-9]\+:[0-9]\+:\|\/.*]] .. username .. [[\/.*\.[cpph]\+:[0-9]\+]]
local python_line = [[^[ ]\+File "[^"]*\n\?.*".*]]
local file = cpp_line .. [[\|]] .. python_line
local search_cmd = "<cmd>set nowrapscan<CR>G?.<CR>k?"
  .. cmd_line
  .. [[<CR><cmd>silent!/]]
  .. file
  .. [[<CR><cmd>set wrapscan<CR>]]

-- OPEN C++/PYTHON on ERROR
local function set_terminal_keymaps()
  local opts = { buffer = 0 }
  -- vim.keymap.set("t", "<esc>", function() vim.cmd("stopinsert") end, opts)
  vim.keymap.set("t", "jj", function()
    vim.cmd("stopinsert")
  end, opts)
  vim.keymap.set("t", "kk", function()
    vim.cmd("stopinsert")
  end, opts)
  -- need to enter normal mode before command and re-enter interactive mode after:
  vim.keymap.set("t", "<C-f>", [[<C-\><C-n>]] .. search_cmd, opts)
  vim.keymap.set("n", "<C-f>", search_cmd, opts)
  vim.keymap.set("n", "gf", open_file_under_cursor, opts)
  vim.keymap.set("t", "<c-l>", [[<cmd>TmuxNavigateRight<cr>]], opts)
  vim.keymap.set("t", "<c-h>", [[<cmd>TmuxNavigateLeft<cr>]], opts)
  vim.keymap.set("t", "<c-j>", [[<cmd>TmuxNavigateDown<cr>]], opts)
  vim.keymap.set("t", "<C-K>", function()
    misc_util.go_to_text_buffer()
  end, { desc = "Go to upper window" })
end

local was_insert = true

local function set_terminal_autocommands()
  local buf = vim.api.nvim_win_get_buf(0)

  vim.api.nvim_create_autocmd("BufEnter", {
    buffer = buf,
    callback = function()
      if was_insert then
        vim.cmd.startinsert()
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = buf,
    callback = function()
      was_insert = vim.api.nvim_get_mode().mode == "t"
    end,
  })
end

-- vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*bash",
  callback = function(ev)
    if vim.bo.filetype == "snacks_terminal" then
      set_terminal_keymaps()
      -- remember if was in insert mode ore not
      set_terminal_autocommands()
      vim.cmd.startinsert()
    end
  end,
})

return M
