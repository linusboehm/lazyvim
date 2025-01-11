M = {}

local filetype = ""
local out_buf = -1
local scratch_win = -1
local out_win = -1

function M.get_filetype()
  if filetype ~= "" then
    local tmp = filetype
    filetype = ""
    return tmp
  end
  if vim.bo.buftype == "" and vim.bo.filetype ~= "" then
    return vim.bo.filetype
  end
  return "markdown"
end

local defaults = {
  name = "Output",
  ft = vim.bo.filetype,
  ---@type string|string[]?
  icon = nil, -- `icon|{icon, icon_hl}`. defaults to the filetype icon
  win = { style = "output" },
}

local height = 20
Snacks.config.style("output", {
  width = 0,
  height = height,
  backdrop = false,
  row = vim.api.nvim_get_option_value("lines", {}) - height,
  bo = { buftype = "nofile", buflisted = false, bufhidden = "wipe", swapfile = false, undofile = false },
  minimal = false,
  noautocmd = false,
  zindex = 100,
  ft = "output",
  wo = { winhighlight = "NormalFloat:Normal", colorcolumn = "" },
})

--- Show lines in a floating buffer at the bottom.
---@param lines string
---@param opts? snacks.scratch.Config
local function show_output(lines, opts)
  opts = Snacks.config.get("output", defaults, opts)
  opts.win = Snacks.win.resolve("output", opts.win, { show = false })
  scratch_win = vim.api.nvim_get_current_win()

  local old_buf = true

  if not vim.api.nvim_buf_is_valid(out_buf) or not vim.api.nvim_buf_is_loaded(out_buf) then
    out_buf = vim.api.nvim_create_buf(false, true)
    old_buf = false
  end

  local content = {}
  for line in lines:gmatch("([^\n]*)\n?") do
    table.insert(content, line)
  end
  -- Remove trailing empty lines
  for i = #content, 1, -1 do
    if content[i] == "" then
      table.remove(content, i)
    else
      break
    end
  end
  vim.api.nvim_buf_set_lines(out_buf, 0, -1, false, content)

  if old_buf then
    -- when reusing an old output buffer, just focus on the window and return
    vim.api.nvim_set_current_win(out_win)
    return
  end

  opts.win.buf = out_buf

  vim.api.nvim_create_autocmd("BufLeave", {
    group = vim.api.nvim_create_augroup("output_leave_" .. out_buf, { clear = true }),
    buffer = out_buf,
    callback = function()
      if vim.api.nvim_win_is_valid(scratch_win) then
        Snacks.notify.info("Left output buffer. Going to win: " .. scratch_win)
        vim.defer_fn(function()
          vim.api.nvim_set_current_win(scratch_win)
        end, 0) -- Delay of 10 milliseconds
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufHidden", {
    group = vim.api.nvim_create_augroup("ouput_leave_" .. out_buf, { clear = true }),
    buffer = out_buf,
    callback = function()
      Snacks.notify.info("Output buffer closed.")
      out_buf = -1
    end,
  })
  opts.win.keys = opts.win.keys or {}
  opts.win.keys.reset = { "q", function() vim.cmd([[close]]) end, desc = "close" }

  local ret = Snacks.win(opts.win):show()
  -- save output window, in case we re-use it
  out_win = vim.api.nvim_get_current_win()
  return ret
end

--- Run the current buffer or a range of lines.
--- Shows the output of `print` inlined with the code.
--- Any error will be shown as a diagnostic.
---@param opts? {name?:string, buf?:number, print?:boolean}
function M.run_python(opts)
  local ns = vim.api.nvim_create_namespace("snacks_debug")
  opts = vim.tbl_extend("force", { print = true }, opts or {})
  local buf = opts.buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local name = opts.name or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")

  -- Get the lines to run
  local lines ---@type string[]
  local mode = vim.fn.mode()
  if mode:find("[vV]") then
    if mode == "v" then
      vim.cmd("normal! v")
    elseif mode == "V" then
      vim.cmd("normal! V")
    end
    local from = vim.api.nvim_buf_get_mark(buf, "<")
    local to = vim.api.nvim_buf_get_mark(buf, ">")

    -- for some reason, sometimes the column is off by one
    -- see: https://github.com/folke/snacks.nvim/issues/190
    local col_to = math.min(to[2] + 1, #vim.api.nvim_buf_get_lines(buf, to[1] - 1, to[1], false)[1])

    lines = vim.api.nvim_buf_get_text(buf, from[1] - 1, from[2], to[1] - 1, col_to, {})
    -- Insert empty lines to keep the line numbers
    for _ = 1, from[1] - 1 do
      table.insert(lines, 1, "")
    end
    vim.fn.feedkeys("gv", "nx")
  else
    lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  end

  -- Clear diagnostics and extmarks
  local function reset()
    vim.diagnostic.reset(ns, buf)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
  reset()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = vim.api.nvim_create_augroup("snacks_debug_run_" .. buf, { clear = true }),
    buffer = buf,
    callback = reset,
  })

  local command = "echo " .. vim.fn.shellescape(table.concat(lines, "\n")) .. " | python3 2>&1"
  local handle = io.popen(command)
  if not handle then
    Snacks.notify.error("Didn't get popen handle.", { title = name })
    return
  end
  local out = handle:read("*a")
  handle:close()

  if out == "" then
    Snacks.notify.info("No output.", { title = name, ft = "python" })
  else
    show_output(out)
  end
end

function M.scratch_ft(ft)
  filetype = ft
  Snacks.scratch()
end

return M
