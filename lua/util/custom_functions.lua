local misc_util = require("util.misc")

local M = {}

-- this is a script to turn dict() calls in python to {}
M.dict_to_squiggle_py = function()
  -- Get the current cursor position
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- Convert to 0-based index
  vim.api.nvim_buf_set_text(0, row, col, row, col, { "", "" })
  row = row + 1

  -- Get the line under the cursor
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]

  -- Find the start of the `dict()` call
  local start_pos = line:find("dict%(")
  if not start_pos then
    print("No 'dict()' call found on the current line.")
    return
  end

  -- Use `%` to find the matching closing parenthesis
  vim.cmd("normal! %")
  local end_row, end_col = unpack(vim.api.nvim_win_get_cursor(0))
  end_row = end_row - 1 -- Convert to 0-based index
  vim.api.nvim_buf_set_text(0, end_row, end_col + 1, end_row, end_col + 1, { "", "" })

  -- Collect the range of lines containing the `dict()` call
  local dict_lines = vim.api.nvim_buf_get_lines(0, row, end_row + 1, false)
  local dict_call = table.concat(dict_lines, " ")
  Snacks.notify.info(dict_call)

  -- Pattern to match and transform the `dict()` call
  local pattern = "dict%((.*)%)"
  local updated_call = dict_call:gsub(pattern, function(args)
    local converted_args = args:gsub("([%w_]+)=", '"%1": ')
    return "{" .. converted_args .. "}"
  end)

  -- Replace the lines in the buffer
  if updated_call ~= dict_call then
    vim.api.nvim_buf_set_lines(0, row, end_row + 1, false, { updated_call })
    print("Replaced multi-line 'dict()' call.")
  else
    print("No valid 'dict()' call found.")
  end

  vim.api.nvim_buf_set_mark(0, "<", row + 1, 0, {})
  vim.api.nvim_buf_set_mark(0, ">", row + 2, 0, {})
  vim.api.nvim_feedkeys("gv", "n", false)
  vim.defer_fn(function()
    require("conform").format({ async = true, lsp_fallback = true }, function()
      vim.defer_fn(function()
        vim.api.nvim_input("<esc>")
      end, 1)
    end)
  end, 1)
end

M.open_qa = function()
  local path = vim.api.nvim_buf_get_name(0)
  local qa_path = path:gsub("prod", "qa")
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.cmd('wincmd w')
  misc_util.open_file(qa_path, row)
end

M.open_prod = function()
  local path = vim.api.nvim_buf_get_name(0)
  path = path:gsub("%-qa%-", "-")
  local qa_path = path:gsub("%/qa%/", "/prod/")
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.cmd('wincmd w')
  misc_util.open_file(qa_path, row)
end

return M
