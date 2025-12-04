local M = {}

function M.file_exists(name)
  -- vim.print("checking if " .. name .. " exists.")
  local f = io.open(name, "r")
  return f ~= nil and io.close(f)
end

function M.IsInList(v, list)
  for _, entry in ipairs(list) do
    if v == entry then
      return true
    end
  end
  return false
end

function M.go_to_text_buffer()
  local skip_types = { "DiffviewFiles", "aerial", "neo-tree", "dapui_scopes", "dapui_breakpoints", "dapui_stacks",
    "dapui_watches" }
  vim.api.nvim_command([[TmuxNavigateUp]])
  local cnt = 0
  while M.IsInList(vim.bo.filetype, skip_types) and cnt < 5 do
    vim.api.nvim_command([[wincmd l]])
    cnt = cnt + 1
  end
end

function M.open_file(filename, line_nr, col_nr)
  local f = vim.fn.findfile(filename, "**")
  if f == "" then
    Snacks.notify.warn("Couldn't find file")
    return false
  else
    M.go_to_text_buffer()
    vim.schedule(function()
      if col_nr == nil then
        col_nr = "1"
      end
      Snacks.notify.info(("Opening: %s:%s:%s"):format(f, line_nr, col_nr - 1))
      vim.cmd("e " .. f)
      if line_nr ~= nil then
        vim.api.nvim_win_set_cursor(0, { tonumber(line_nr), tonumber(col_nr) - 1 })
      end
    end)
  end
end

return M
