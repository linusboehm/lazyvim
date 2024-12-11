local M = {}

local misc_util = require("util.misc")
local CoreUtil = require("lazy.core.util")

local function run_cmd(cmd)
  local keys = [[<esc>i<C-e><C-u>]] .. cmd .. [[<CR>]]
  local key = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(key, "n", false)
end

function M.go_to_terminal(cb)
  for _ = 1, 5 do
    -- term://~/repos/trading_platform/scripts//28571:/bin/bash;#toggleterm#1
    -- if string.find(vim.fn.expand("%"), "/bin/bash;#toggleterm") then
    if vim.bo.filetype == "snacks_terminal" then
      cb()
      return
    end
    vim.api.nvim_command([[wincmd j]])
  end
  local opts = {win = { on_buf = cb  }}
  Snacks.terminal(nil, opts)
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
  M.go_to_terminal(cb)
  vim.schedule(function()
    vim.api.nvim_set_current_win(curr_win)
  end)
end

-- HELPER FUNCTIONS
local open_file_under_cursor = function()
  local filename = vim.fn.expand("<cfile>")
  -- Define the pattern to search for
  local pattern = filename .. [[:(\d*):(\d*)]]

  -- Search for the pattern under the cursor
  vim.fn.search(pattern, "c")

  -- Get the current line and extract the match
  local line = vim.api.nvim_get_current_line()
  local line_nr, col_nr = line:match(filename .. ":?(%d*):?(%d*)")
  line_nr = line_nr ~= "" and line_nr or nil
  col_nr = col_nr ~= "" and col_nr or "2"

  misc_util.open_file(filename, line_nr, col_nr)
end

-- local open_python_file = function(line)
--
--   local _, _, path, line_nr = string.find(line, '"([^"]*)".*line (%d+)')
--   CoreUtil.info("trying to open: " .. path .. ":" .. line_nr, { title = "filename" })
--   misc_util.open_file_at_location(path, line_nr, 1)
--
--   -- local Util = require("lazyvim.util")
--   -- Util.telescope("find_files", {
--   --   default_text = default_text,
--   --   cwd = git_root,
--   --   on_complete = {
--   --     function(picker)
--   --       require("telescope.actions").select_default(picker.prompt_bufnr)
--   --     end,
--   --   },
--   -- })()
-- end

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
  vim.keymap.set("t", "<esc>", function() vim.cmd("stopinsert") end, opts)
  vim.keymap.set("t", "jj",    function() vim.cmd("stopinsert") end, opts)
  vim.keymap.set("t", "kk",    function() vim.cmd("stopinsert") end, opts)
  -- need to enter normal mode before command and re-enter interactive mode after:
  vim.keymap.set("t", "<C-f>", [[<C-\><C-n>]] .. search_cmd, opts)
  vim.keymap.set("n", "<C-f>", search_cmd, opts)
  vim.keymap.set("n", "gf", open_file_under_cursor, opts)
end

-- vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*bash",
  callback = function(ev)
    if vim.bo.filetype == "snacks_terminal" then
      Snacks.notify("Terminal opened!")
      set_terminal_keymaps()
    end
  end,
})

return M
