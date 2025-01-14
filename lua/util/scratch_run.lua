M = {}

local width = math.floor(vim.api.nvim_get_option("columns") * 0.4)
local height = math.floor(vim.api.nvim_get_option("lines") * 0.8)
local padding = 2
local boarder = math.floor((vim.api.nvim_get_option("columns") - 2 * width - padding) / 2)

local invalid_windows = {
  source = { win = -1, buf = -1 },
  out = { win = -1, buf = -1 },
  asm = { win = -1, buf = -1 },
}

M.opts = { win = { width = width, height = height, padding = padding, boarder = boarder } }

local open_windows = invalid_windows

local reset_windows = function()
  for _, w in pairs(open_windows) do
    if vim.api.nvim_buf_is_valid(w.buf) then
      vim.api.nvim_buf_delete(w.buf, {})
    end
    if vim.api.nvim_win_is_valid(w.win) then
      vim.api.nvim_win_close(w.win, true)
    end
  end
  open_windows = invalid_windows
end

local filetype = ""

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

Snacks.config.style("output", {
  width = M.opts.win.width,
  height = M.opts.win.height,
  col = M.opts.win.boarder + M.opts.win.width + M.opts.win.padding,
  backdrop = false,
  bo = { buftype = "nofile", buflisted = false, bufhidden = "wipe", swapfile = false, undofile = false },
  minimal = false,
  noautocmd = false,
  border = "rounded",
  -- footer_pos = "center",
  zindex = 20,
  ft = "output",
  wo = { winhighlight = "NormalFloat:Normal", colorcolumn = "", number = false, relativenumber = false },
})

--- Show lines in a floating buffer at the bottom.
---@param lines string
local function prepare_buf(lines, win)
  local new_buf = win.buf
  if not vim.api.nvim_buf_is_valid(new_buf) or not vim.api.nvim_buf_is_loaded(new_buf) then
    new_buf = vim.api.nvim_create_buf(false, true)
  --   vim.api.nvim_create_autocmd({"BufHidden", "BufUnload"}, {
  --     group = vim.api.nvim_create_augroup("run_autoclose_" .. new_buf, { clear = true }),
  --     buffer = new_buf,
  --     callback = function()
  --       reset_windows()
  --     end,
  --   })
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

  if lines ~= "" then
    vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, content)
  end
  win.buf = new_buf
end

---@param opts? snacks.scratch.Config
local function create_window(opts, win_opts)
  if vim.api.nvim_win_is_valid(win_opts.win) then
    return false
  end
  opts = Snacks.config.get("output", defaults, opts)
  opts.win = Snacks.win.resolve("output", opts.win, { show = false })
  opts.win.buf = win_opts.buf
  opts.win.keys = {
    source = {
      "<cr>",
      function()
        vim.api.nvim_set_current_win(open_windows.source.win)
      end,
      desc = "go to source",
    },
  }
  local ret = Snacks.win(opts.win)

  ret:show()
  win_opts.win = vim.api.nvim_get_current_win()
  return ret
end

local set_keys = function()
  local change_win = function(w)
    if vim.api.nvim_win_is_valid(w) then
      vim.api.nvim_set_current_win(w)
    end
  end

  local opts
  if vim.api.nvim_win_is_valid(open_windows.source.win) then
    opts = { buffer = open_windows.source.buf, nowait = true }
    vim.keymap.set("n", "<c-l>", function()
      change_win(open_windows.out.win)
    end, opts)
    vim.keymap.set("n", "<c-h>", function()
      change_win(open_windows.out.win)
    end, opts)
    vim.keymap.set("n", "<c-k>", function() end, opts)
    vim.keymap.set("n", "<c-j>", function() end, opts)
  end

  if vim.api.nvim_win_is_valid(open_windows.out.win) then
    opts = { buffer = open_windows.out.buf, nowait = true }
    vim.keymap.set("n", "<c-l>", function()
      change_win(open_windows.source.win)
    end, opts)
    vim.keymap.set("n", "<c-h>", function()
      change_win(open_windows.source.win)
    end, opts)
    vim.keymap.set("n", "<c-k>", function()
      change_win(open_windows.asm.win)
    end, opts)
    vim.keymap.set("n", "<c-j>", function()
      change_win(open_windows.asm.win)
    end, opts)
  end

  if vim.api.nvim_win_is_valid(open_windows.asm.win) then
    opts = { buffer = open_windows.asm.buf, nowait = true }
    vim.keymap.set("n", "<c-l>", function()
      change_win(open_windows.source.win)
    end, opts)
    vim.keymap.set("n", "<c-h>", function()
      change_win(open_windows.source.win)
    end, opts)
    vim.keymap.set("n", "<c-k>", function()
      change_win(open_windows.out.win)
    end, opts)
    vim.keymap.set("n", "<c-j>", function()
      change_win(open_windows.out.win)
    end, opts)
  end
end

local function get_lines(buf)
  local ns = vim.api.nvim_create_namespace("snacks_debug")
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

  return lines
end

local function create_single_out(text)
  prepare_buf(text, open_windows.out)
  create_window(opts, open_windows.out)
end

local function create_double_out(text1, text2)
  prepare_buf(text1, open_windows.out)
  local top_row = math.floor((vim.api.nvim_get_option("lines") - M.opts.win.height) / 2) - 1
  local half_height = math.floor(M.opts.win.height / 2) - padding / 2
  local opts = {
    win = {
      width = M.opts.win.width,
      height = half_height,
      row = top_row,
    },
  }
  create_window(opts, open_windows.out)

  prepare_buf(text2, open_windows.asm)
  opts = {
    win = {
      width = M.opts.win.width,
      height = half_height,
      row = top_row + half_height + padding,
    },
  }
  create_window(opts, open_windows.asm)
end

local function prepare_ui(num_out_wins)
  open_windows.source.win = vim.api.nvim_get_current_win()
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(open_windows.source.win),
    callback = function()
      vim.api.nvim_win_call(open_windows.source.win, function()
        vim.cmd("silent! write")
      end)
      reset_windows()
    end,
  })

  opts = vim.tbl_extend("force", { print = true }, opts or {})
  local buf = opts.buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  open_windows.source.buf = buf

  if num_out_wins == 1 then
    create_single_out("")
  elseif num_out_wins == 2 then
    create_double_out("", "")
  end
end

--- Run the current buffer or a range of lines.
--- Shows the output of `print` inlined with the code.
--- Any error will be shown as a diagnostic.
---@param opts? {name?:string, buf?:number, print?:boolean}
function M.run_python(opts)
  prepare_ui(1)

  local name = opts.name or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(open_windows.source.buf), ":t")
  local lines = get_lines(open_windows.source.buf)

  local command = "echo " .. vim.fn.shellescape(table.concat(lines, "\n")) .. " | python3 2>&1"
  local handle = io.popen(command)
  if not handle then
    Snacks.notify.error("Didn't get popen handle.", { title = name })
    return
  end
  local stdout = handle:read("*a")
  handle:close()

  if stdout == "" then
    Snacks.notify.info("No output.", { title = name, ft = "python" })
  else
    create_single_out(stdout)
    vim.api.nvim_set_current_win(open_windows.source.win)
  end
  set_keys()
end

--- Run the current buffer or a range of lines.
--- Shows the output of `print` inlined with the code.
--- Any error will be shown as a diagnostic.
---@param opts? {name?:string, buf?:number, print?:boolean, win?:table}
function M.run_cpp(opts, picker)
  prepare_ui(2)

  vim.api.nvim_set_current_win(open_windows.source.win)
  local start_line, end_line
  local mode = vim.fn.mode()

  if mode:find("[vV]") then
    start_line = vim.fn.line("'<")
    end_line = vim.fn.line("'>")
  else
    start_line = 1
    end_line = vim.fn.line("$")
  end

  opts = { ft = "cpp", asm = open_windows.asm, out = open_windows.out, exec = true }
  local bang = false
  require("godbolt.cmd").godbolt(start_line, end_line, bang, picker, opts)
  set_keys()
end

function M.scratch_ft(ft, config)
  filetype = ft
  Snacks.scratch(config)
end

return M
