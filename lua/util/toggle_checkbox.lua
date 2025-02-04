local M = {}

local checked_character = "x"

local checked_checkbox = "%[" .. checked_character:lower() .. "%]"
local upper_checked_checkbox = "%[" .. checked_character:upper() .. "%]"
local unchecked_checkbox = "%[ %]"

local line_contains_unchecked = function(line)
  return line:lower():find(unchecked_checkbox)
end

local line_contains_checked = function(line)
  return line:lower():find(checked_checkbox)
end

local line_with_checkbox = function(line)
  -- return not line_contains_a_checked_checkbox(line) and not line_contains_an_unchecked_checkbox(line)
  local lower_line = line:lower()
  return lower_line:find("^%s*- " .. checked_checkbox)
    or lower_line:find("^%s*- " .. unchecked_checkbox)
    or lower_line:find("^%s*%d%. " .. checked_checkbox)
    or lower_line:find("^%s*%d%. " .. unchecked_checkbox)
end

local checkbox = {
  check = function(line)
    return line:gsub(unchecked_checkbox, checked_checkbox, 1)
  end,

  uncheck = function(line)
    return line:gsub(checked_checkbox, unchecked_checkbox, 1):gsub(upper_checked_checkbox, unchecked_checkbox, 1)
  end,

  make_checkbox = function(line)
    if not line:match("^%s*-%s.*$") and not line:match("^%s*%d%s.*$") then
      -- "xxx" -> "- [ ] xxx"
      return line:gsub("(%S+)", "- [ ] %1", 1)
    else
      -- "- xxx" -> "- [ ] xxx", "3. xxx" -> "3. [ ] xxx"
      return line:gsub("(%s*- )(.*)", "%1[ ] %2", 1):gsub("(%s*%d%. )(.*)", "%1[ ] %2", 1)
    end
  end,
}

M.toggle = function()
  local bufnr = vim.api.nvim_win_get_buf(0)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local start_line = cursor[1] - 1
  local end_line = start_line
  local start_mark
  local end_mark

  local mode = vim.fn.mode()
  if mode:find("[vV]") then
    if mode == "v" then
      vim.cmd("normal! v")
    elseif mode == "V" then
      vim.cmd("normal! V")
    end
    start_mark = vim.api.nvim_buf_get_mark(bufnr, "<")
    end_mark = vim.api.nvim_buf_get_mark(bufnr, ">")
    start_line = start_mark[1] - 1
    end_line = end_mark[1] - 1
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
  local any_with_checkbox = false
  local all_checked = true

  for _, line in ipairs(lines) do
    if line_with_checkbox(line) then
      any_with_checkbox = true
      if not line_contains_checked(line) then
        all_checked = false
      end
    end
  end

  local new_lines = {}
  for i, line in ipairs(lines) do
    if line == "" then
      table.insert(new_lines, i, line)
    else
      if not any_with_checkbox then -- no checkboxes -> insert checkbox to all lines
        local new_line = checkbox.make_checkbox(line)
        table.insert(new_lines, new_line)
      elseif line_with_checkbox(line) then
        if all_checked then
          local new_line = checkbox.uncheck(line)
          table.insert(new_lines, i, new_line)
        else
          local new_line = checkbox.check(line)
          table.insert(new_lines, i, new_line)
        end
      else
        table.insert(new_lines, i, line)
      end
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, start_line, end_line + 1, false, new_lines)

  -- if mode:find("[vV]") then
  --   vim.api.nvim_buf_set_mark(bufnr, "<", start_mark[1], start_mark[2], {})
  --   vim.api.nvim_buf_set_mark(bufnr, ">", end_mark[1], end_mark[2], {})
  --   vim.cmd("normal! gv")
  -- end

  vim.api.nvim_win_set_cursor(0, cursor)
  vim.cmd([[silent! call repeat#set("\<cmd>lua require('util.toggle_checkbox').toggle()\<CR>")]])
end

return M
