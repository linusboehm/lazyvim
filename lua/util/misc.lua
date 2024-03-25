local M = {}

-- returns the git root directory
---@return string
function M.get_git_root()
  local dot_git_path = vim.fs.dirname(vim.fs.find({ ".git" }, { upward = true })[1])
  if dot_git_path == nil then
    dot_git_path = vim.fs.dirname(vim.fs.find({ ".github" }, { upward = true })[1])
  end
  if dot_git_path == nil then
    dot_git_path = "/"
  end
  return dot_git_path
end

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

local function dump2(o, indent)
  indent = indent or ""
  if o == nil then
    return ""
  end
  if indent == "     " then
    return "abort"
  end
  for key, value in pairs(o) do
    if type(value) == "table" then
      print(indent .. tostring(key) .. ": ")
      dump(value, indent .. " ")
    else
      print(indent .. tostring(key) .. ": " .. tostring(value))
    end
  end
end

function M.dump(o)
  if type(o) == "table" then
    local s = "{ "
    for k, v in pairs(o) do
      if type(k) ~= "number" then
        k = '"' .. k .. '"'
      end
      s = s .. "[" .. k .. "] = " .. M.dump(v) .. ","
    end
    return s .. "} "
  else
    return tostring(o)
  end
end

function M.go_to_text_buffer()
  -- vim.print("trying to open: " .. filename)
  local skip_types = { "aerial", "neo-tree" }
  vim.api.nvim_command([[wincmd k]])
  local cnt = 0
  while M.IsInList(vim.bo.filetype, skip_types) and cnt < 5 do
    vim.api.nvim_command([[wincmd l]])
    cnt = cnt + 1
  end
end

function M.open_file_at_location(filename, line_nr, col_nr)
  M.go_to_text_buffer()
  vim.cmd("e" .. filename)
  vim.api.nvim_win_set_cursor(0, { tonumber(line_nr), tonumber(col_nr) - 1 })
end

return M
