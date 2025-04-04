local misc_util = require("util.misc")

local M = {}

local function remove_prefix(full_path, prefix)
  local escaped_prefix = vim.pesc(prefix)
  return full_path:gsub("^" .. escaped_prefix, "")
end

function M.build_and_run()
  local handle = io.popen("git rev-parse --show-cdup 2> /dev/null")
  local git_root_rel = handle and handle:read("*a") or ""
  if handle then handle:close() end
  git_root_rel = git_root_rel:gsub("%s+$", "")  -- trim whitespace
  if #git_root_rel == 0 then
    Snacks.notify.info("Not inside a git repository.")
    return
  end
  local git_root = Snacks.git.get_root()
  local source_dir = remove_prefix(vim.fn.expand("%:p:h"), git_root)
  local base = vim.fn.expand("%:t:r")
  local exec_path = "build/gcc-release" .. source_dir .. "/perf_stuff." .. base
  local build_cmd = "cmake --workflow --preset gcc-release"
  local cmd = "(cd " .. git_root_rel .. " && " .. build_cmd .. " && ./" .. exec_path .. ")"
  require("util.toggletem_utils").run_in_terminal(cmd)
end

-- this is a script to turn dict() calls in python to {}
function M.dict_to_squiggle_py ()
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
  vim.cmd("wincmd w")
  misc_util.open_file(qa_path, row)
end

M.open_prod = function()
  local path = vim.api.nvim_buf_get_name(0)
  path = path:gsub("%-qa%-", "-")
  local qa_path = path:gsub("%/qa%/", "/prod/")
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.cmd("wincmd w")
  misc_util.open_file(qa_path, row)
end

return M
