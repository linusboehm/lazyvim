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

function M.dump2(o, indent)
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
      M.dump2(value, indent .. " ")
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
  local skip_types = { "aerial", "neo-tree", "dapui_scopes", "dapui_breakpoints", "dapui_stacks", "dapui_watches" }
  vim.api.nvim_command([[wincmd k]])
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

local function get_color_code(input)
  -- Initialize results

  -- Extract the Semantic Tokens section
  local semantic_tokens_section = input:match("Semantic Tokens(.-)\n\n")
  if semantic_tokens_section then
    -- Find the first entry in the Semantic Tokens section
    local sem_token = semantic_tokens_section:match("links to%s+([%w_%.%@]+)")
    return vim.api.nvim_exec2("hi " .. sem_token, { output = true }).output:match("=(#%x%x%x%x%x%x)")
  end

  -- Extract the Treesitter section
  local treesitter_section = input:match("Treesitter(.-)\n\n")
  if treesitter_section then
    local color_code = nil
    -- Find the last entry in the Treesitter section
    for entry in treesitter_section:gmatch("  %- ([^\n]+)") do
      local sem_token = entry:match("links to%s+([%w_%.%@]+)")
      local curr_color = vim.api.nvim_exec2("hi " .. sem_token, { output = true }).output:match("=(#%x%x%x%x%x%x)")
      if curr_color ~= nil then
        color_code = curr_color
      end
    end
    return color_code
  end

  return nil
end

function M.dump_color_codes()
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  local l_row, l_col = unpack({ 0, 0 })
  local c_row, c_col = unpack(vim.api.nvim_win_get_cursor(0))
  local token_data = {}
  token_data[c_row] = {}

  while c_row ~= l_row or c_col ~= l_col do
    -- advance
    l_row = c_row
    l_col = c_col

    -- get the info
    local word = vim.fn.expand("<cword>")
    local val = vim.api.nvim_exec2("Inspect", { output = true }).output
    local color_code = get_color_code(val)

    -- get next position
    vim.api.nvim_feedkeys("w", "x", true)
    c_row, c_col = unpack(vim.api.nvim_win_get_cursor(0))

    -- vim.print("word: " .. word .. ", row: " .. tostring(c_row) .. ", from to: " .. tostring(l_col) .. ' ' .. tostring(c_col))
    table.insert(token_data[l_row], { word = word, start = l_col, stop = c_col, color = color_code })

    if c_row ~= l_row then
      local line_content = vim.api.nvim_buf_get_lines(0, l_row - 1, l_row, false)[1]
      local line_length = #line_content
      local entries = #token_data[l_row]
      token_data[l_row][entries]["stop"] = line_length
      token_data[l_row][entries]["start"] = l_col
      vim.print("setting " .. token_data[l_row][entries]["word"] .. " to: " .. tostring(l_col))
      l_col = 0
      -- insert new row
      token_data[c_row] = {}
    end
  end

  local len = #token_data[c_row]
  token_data[c_row][len]["stop"] = token_data[c_row][len]["stop"] + 1

  local filename = vim.fn.expand("%:t") .. "_lsp_tokens.json"
  local file = io.open(filename, "w")
  local json = vim.fn.json_encode(token_data)
  file:write(json)
  file:close()
end

function M.dump_color_codes_on_start()
  vim.defer_fn(function()
    M.dump_color_codes()
    vim.api.nvim_exec2("q", { output = false })
  end, 2000)
end
return M
