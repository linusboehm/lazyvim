local M = {}

local main = -1
local Snacks = require("snacks")
local svim = vim.fn.has("nvim-0.11") == 1 and vim or require("snacks.compat")
local uv = vim.uv or vim.loop
local closed = false
---@type snacks.win
local source_win = nil
---@type snacks.win
local stdout_win = nil
---@type snacks.win
local asm_win = nil
local layout = nil
---@type table
local last_opts = {}

---@type snacks.picker.layout.Config
local resolved_layout = nil

---@param filetype? "python"|"cpp"
local get_file = function(filetype)
  local branch = ""
  if uv.fs_stat(".git") then
    local ret = vim.fn.systemlist("git branch --show-current")[1]
    if vim.v.shell_error == 0 then
      branch = ret
    end
  end

  local filekey = {
    tostring(vim.v.count1),
    "",
    "scratch",
    svim.fs.normalize(assert(uv.cwd())),
    branch,
  }

  local root = vim.fn.stdpath("data") .. "/scratch"
  local fname = Snacks.util.file_encode(table.concat(filekey, "|") .. "." .. filetype)
  local file = root .. "/" .. fname
  file = svim.fs.normalize(file)
  return file
end

---@param buf integer
local function get_lines_nrs(buf)
  -- Get the lines to run
  local mode = vim.fn.mode()
  if mode:find("[vV]") then
    if mode == "v" then
      vim.cmd("normal! v")
    elseif mode == "V" then
      vim.cmd("normal! V")
    end
    local start_line, start_col = vim.api.nvim_buf_get_mark(buf, "<")
    local to = vim.api.nvim_buf_get_mark(buf, ">")

    -- for some reason, sometimes the column is off by one
    -- see: https://github.com/folke/snacks.nvim/issues/190
    local end_col = math.min(to[2] + 1, #vim.api.nvim_buf_get_lines(buf, to[1] - 1, to[1], false)[1])

    return start_line[1] - 1, start_col, to[1] - 1, end_col
  else
    return 0, 0, -1, 0
  end
end

---@param buf integer
local function get_lines(buf)
  -- Get the lines to run
  local lines ---@type string[]
  local mode = vim.fn.mode()
  local start_line, start_col, end_line, end_col = get_lines_nrs(buf)
  if mode:find("[vV]") then
    if mode == "v" then
      vim.cmd("normal! v")
    elseif mode == "V" then
      vim.cmd("normal! V")
    end
    lines = vim.api.nvim_buf_get_text(buf, start_line, start_col, end_line, end_col, {})
    -- Insert empty lines to keep the line numbers
    for _ = 1, start_line do
      table.insert(lines, 1, "")
    end
    vim.fn.feedkeys("gv", "nx")
  else
    lines = vim.api.nvim_buf_get_lines(buf, start_line, end_line, false)
  end

  local ns = vim.api.nvim_create_namespace("snacks_debug")
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

--- Execute the callback in normal mode.
--- When still in insert mode, stop insert mode first,
--- and then`vim.schedule` the callback.
---@param cb fun()
local function norm(cb)
  if vim.fn.mode():sub(1, 1) == "i" then
    vim.cmd.stopinsert()
    vim.schedule(cb)
    return
  end
  cb()
  return true
end

local function stopinsert(win)
  -- only stop insert mode if needed
  if not vim.fn.mode():find("^i") then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  -- if the other buffer is a prompt, then don't stop insert mode
  if buf ~= win.buf then
    return
  end
  vim.cmd("stopinsert")
end

local function close(layout)
  stopinsert(source_win)
  if closed then
    return
  end
  closed = true

  -- if self.opts.on_close then
  --   self.opts.on_close(self)
  -- end

  if vim.api.nvim_win_is_valid(main) then
    pcall(vim.api.nvim_set_current_win, main)
  end
  vim.schedule(function()
    source_win:close()
    stdout_win:close()
    asm_win:close()
    layout:close()
  end)
end

---@type snacks.picker.layout.Config
local three_win_layout = {
  layout = {
    box = "horizontal",
    width = 0.8,
    min_width = 120,
    height = 0.8,
    { win = "source", border = "rounded", width = 0.5 },
    {
      box = "vertical",
      border = "none",
      { win = "stdout", height = 0.5, border = "rounded" },
      { win = "asm", border = "rounded" },
    },
  },
}

---@type snacks.picker.layout.Config
local two_win_layout = {
  layout = {
    box = "horizontal",
    width = 0.8,
    min_width = 120,
    height = 0.8,
    { win = "source", border = "rounded", width = 0.5 },
    { win = "stdout", border = "rounded" },
  },
}

--- Focuses the given or configured window.
--- Falls back to the first available window if the window is hidden.
---@param layout snacks.layout
---@param win? "asm"|"stdout"|"source"
---@param opts? {show?: boolean} when enable is true, the window will be shown if hidden
local function focus(layout, win, opts)
  opts = opts or {}
  local ret ---@type snacks.win?
  for _, name in ipairs({ "asm", "stdout", "source" }) do
    local w = layout.wins[name]
    if w and w:valid() and not layout:is_hidden(name) then
      if name == win then
        ret = w
        break
      end
      ret = ret or w
    end
  end
  if ret then
    ret:focus()
  end
end

local get_defult_args = function()
  local start_line, _, end_line, _ = get_lines_nrs(source_win.buf)
  return {
    line1 = start_line + 1,
    line2 = end_line,
    asm_buf = asm_win.buf,
    compiler = { id = "g141" },
    flags = "-O1",
    default_flags = "-fsanitize=address -std=c++20 -O0",
    lang = "c++",
    out_buf = stdout_win.buf,
    on_opts_callback = function(opts)
      local title = "asm ("
      if opts.flags ~= "" then
        title = title .. opts.flags .. ", "
      end
      title = title .. opts.compiler.name .. ")"
      if opts.flags then
        asm_win:set_title(title, "center")
      else
        asm_win:set_title("asm", "center")
      end
      last_opts = opts
    end,
  }
end

---@class scratch_run.run_opts
---@field asm_buf? integer
---@field bang? boolean
---@field compiler? ce.compile.compiler
---@field fargs? table
---@field flags? string
---@field default_flags? string
---@field lang? string
---@field out_buf? integer
---@field on_opts_callback? function

---@param opts scratch_run.run_opts
local function run_cpp(opts)
  require("compiler-explorer").compile(opts)
end

local default_actions = {
  focus_stdout = function()
    focus(layout, "stdout", { show = true })
  end,
  focus_asm = function()
    focus(layout, "asm", { show = true })
  end,
  focus_source = function()
    focus(layout, "source", { show = true })
  end,
  show_tooltip = function()
    require("compiler-explorer").show_tooltip()
  end,
  close = function()
    norm(function()
      close(layout)
    end)
  end,
  run_cpp_o0 = function()
    local opts = vim.tbl_extend("force", get_defult_args(), { flags = "-O0" })
    run_cpp(opts)
  end,
  run_cpp_o1 = function()
    local opts = vim.tbl_extend("force", get_defult_args(), { flags = "-O1" })
    run_cpp(opts)
  end,
  run_cpp_o2 = function()
    local opts = vim.tbl_extend("force", get_defult_args(), { flags = "-O2" })
    run_cpp(opts)
  end,
  run_cpp_o3 = function()
    local opts = vim.tbl_extend("force", get_defult_args(), { flags = "-O3" })
    run_cpp(opts)
  end,
  run_cpp_last = function()
    -- buffer numbers have to be rest in case they changed
    last_opts.asm_buf = nil
    last_opts.out_buf = nil
    local opts = vim.tbl_extend("force", get_defult_args(), last_opts)
    run_cpp(opts)
  end,
  run_cpp_asan = function()
    local opts = vim.tbl_extend("force", get_defult_args(), { flags = "-fsanitize=address -std=c++20 -O0" })
    run_cpp(opts)
  end,
  run_cpp_picker = function()
    local opts = get_defult_args()
    opts.compiler = nil
    opts.flags = nil
    run_cpp(opts)
  end,
  run_py = function()
    local lines = get_lines(source_win.buf)
    local command = "echo " .. vim.fn.shellescape(table.concat(lines, "\n")) .. " | python3 2>&1"
    local handle = io.popen(command)
    if not handle then
      Snacks.notify.error("Didn't get popen handle.")
      return
    end
    local stdout = handle:read("*a")
    handle:close()

    if stdout == "" then
      Snacks.notify.info("No output.", { ft = "python" })
    else
      local content = {}
      for line in stdout:gmatch("([^\n]*)\n?") do
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
      vim.api.nvim_buf_set_lines(stdout_win.buf, 0, -1, false, content)
    end
  end,
}

local default_keys = {
  ["<c-l>"] = { "focus_stdout", mode = { "i", "n" } },
  ["<c-h>"] = { "focus_stdout", mode = { "i", "n" } },
  ["q"] = "close",
}

---@type snacks.win.Config
local source_opts = {
  bo = { buftype = "", buflisted = false, bufhidden = "hide", swapfile = false },
  wo = { winhighlight = "NormalFloat:Normal" },
  minimal = false,
  footer_pos = "center",
  keys = default_keys,
  fixbuf = true,
  actions = default_actions,
}

---@type snacks.win.Config
local out_opts = {
  bo = {
    bufhidden = "wipe",
    buftype = "nofile",
    buflisted = false,
    swapfile = false,
    undofile = false,
  },
  wo = { winhighlight = "NormalFloat:Normal" },
  minimal = true,
  footer_pos = "center",
  fixbuf = true,
  actions = default_actions,
}
---@type snacks.win.Config
local stdout_opts = vim.tbl_extend("force", out_opts, {
  keys = {
    ["q"] = "close",
    ["<c-l>"] = { "focus_source", mode = { "i", "n" } },
    ["<c-h>"] = { "focus_source", mode = { "i", "n" } },
    ["<c-k>"] = { "focus_asm", mode = { "i", "n" } },
    ["<c-j>"] = { "focus_asm", mode = { "i", "n" } },
  },
})
---@type snacks.win.Config
local asm_opts = vim.tbl_extend("force", out_opts, {
  bo = {
    filetype = "asm",
  },
  keys = {
    ["q"] = "close",
    ["<c-l>"] = { "focus_source", mode = { "i", "n" } },
    ["<c-h>"] = { "focus_source", mode = { "i", "n" } },
    ["<c-k>"] = { "focus_stdout", mode = { "i", "n" } },
    ["<c-j>"] = { "focus_stdout", mode = { "i", "n" } },
    ["K"] = { "show_tooltip" },
  },
})

---@param opts snacks.win.Config
local function get_vim_with_key_desc(opts)
  local win = Snacks.win(opts)
  win.opts.footer = win.opts.footer or {}

  table.sort(win.keys, function(a, b)
    return a[1] < b[1]
  end)

  for _, key in ipairs(win.keys) do
    local keymap = vim.fn.keytrans(vim.keycode(key[1]))
    if not key.desc or not (string.find(key.desc, "focus") or string.find(key.desc, "-O")) then
      table.insert(win.opts.footer, { " " })
      table.insert(win.opts.footer, { " " .. keymap .. " ", "SnacksScratchKey" })
      table.insert(win.opts.footer, { " " .. (key.desc or keymap) .. " ", "SnacksScratchDesc" })
    end
  end

  table.insert(win.opts.footer, { " " })

  table.sort(win.keys, function(a, b)
    return a[1] < b[1]
  end)
  return win
end

local current_win = function(layout)
  local current = vim.api.nvim_get_current_win()
  for w, win in pairs(layout.wins or {}) do
    if win.win == current then
      return w, win
    end
  end
end

local function is_focused(layout)
  return current_win(layout) ~= nil
end

local update_titles = function()
  source_win:set_title("source", "center")
  stdout_win:set_title("stdout", "center")
  asm_win:set_title("asm", "center")
end

local attach = function(layout)
  pcall(vim.api.nvim_set_current_win, source_win.win)

  -- close if we enter a window that is not part of the picker
  layout.root:on("WinEnter", function()
    if closed or Snacks.util.is_float() then
      return
    end
    if is_focused(layout) then
      return
    end
    -- close picker when we enter another window
    vim.schedule(function()
      close(layout)
    end)
  end)

  -- Check if we need to auto close any picker windows
  layout.root:on("WinEnter", function()
    if not is_focused(layout) then
      return
    end
    local current = current_win(layout)
    for name, win in pairs(layout.wins) do
      local auto_hide = vim.tbl_contains(resolved_layout.auto_hide or {}, name)
      if name ~= current and auto_hide and win:valid() then
        Snacks.notify.error("we should probably auto close stuff")
        -- self:toggle(name, { enable = false })
      end
    end
  end)

  -- prevent entering the root window for split layouts
  local left_picker = true -- left a picker window
  local last_pwin ---@type number?
  layout.root:on("WinLeave", function()
    left_picker = is_focused(layout)
  end)
  layout.root:on("WinEnter", function()
    if is_focused(layout) then
      last_pwin = vim.api.nvim_get_current_win()
    end
  end)
  layout.root:on("WinEnter", function()
    if left_picker then
      local pos = layout.root.opts.position
      local wincmds = { left = "l", right = "h", top = "j", bottom = "k" }
      vim.cmd("wincmd " .. wincmds[pos])
    elseif last_pwin and vim.api.nvim_win_is_valid(last_pwin) then
      vim.api.nvim_set_current_win(last_pwin)
    else
      Snacks.notify.error("we probably should do the right thing and focus")
      -- if vim.api.nvim_win_is_valid(main) then
      --   pcall(vim.api.nvim_set_current_win, main)
      -- end
    end
  end, { buf = true, nested = true })

  vim.api.nvim_create_autocmd("BufHidden", {
    group = vim.api.nvim_create_augroup("snacks_run_autowrite_" .. source_win.buf, { clear = true }),
    buffer = source_win.buf,
    callback = function(ev)
      vim.api.nvim_buf_call(ev.buf, function()
        vim.cmd("silent! write")
      end)
    end,
  })
end

---@param filetype "python"|"cpp"
M.open_scratch_run = function(filetype)
  main = vim.api.nvim_get_current_win()
  closed = false

  local source_buf = vim.fn.bufadd(get_file(filetype))
  if not vim.api.nvim_buf_is_loaded(source_buf) then
    vim.fn.bufload(source_buf)
  end

  local opts = two_win_layout --[[@as snacks.layout.Config]]
  source_opts.keys = default_keys
  if filetype == "cpp" then
    opts = three_win_layout --[[@as snacks.layout.Config]]
    source_opts.keys = vim.tbl_extend("force", source_opts.keys, {
      ["<cr><cr>"] = { "run_cpp_last", mode = { "n", "v" }, desc = "run last" },
      ["<cr>0"] = { "run_cpp_o0", mode = { "n", "v" }, desc = "-O0" },
      ["<cr>1"] = { "run_cpp_o1", mode = { "n", "v" }, desc = "-O1" },
      ["<cr>2"] = { "run_cpp_o2", mode = { "n", "v" }, desc = "-O3" },
      ["<cr>3"] = { "run_cpp_o3", mode = { "n", "v" }, desc = "-O3" },
      ["<cr>a"] = { "run_cpp_asan", mode = { "n", "v" }, desc = "asan" },
      ["<cr>p"] = { "run_cpp_picker", mode = { "n", "v" }, desc = "picker" },
    })
    source_opts.footer = {}
    table.insert(source_opts.footer, { " " })
    table.insert(source_opts.footer, { " <cr><cr> ", "SnacksScratchKey" })
    table.insert(source_opts.footer, { " -O3 ", "SnacksScratchDesc" })
    table.insert(source_opts.footer, { " " })
    table.insert(source_opts.footer, { " <cr>0-3 ", "SnacksScratchKey" })
    table.insert(source_opts.footer, { " -O0-3 ", "SnacksScratchDesc" })
  else
    source_opts.keys = vim.tbl_extend("force", source_opts.keys, {
      ["<cr>"] = { "run_py", mode = { "n", "v" }, desc = "run" },
    })
  end
  source_opts.bo.filetype = filetype
  source_opts.buf = source_buf

  source_win = get_vim_with_key_desc(source_opts)
  stdout_win = Snacks.win(stdout_opts)
  -- asm_win = Snacks.win(asm_opts)
  asm_win = get_vim_with_key_desc(asm_opts)

  layout = Snacks.layout.new(vim.tbl_deep_extend("force", opts, {
    show = false,
    win = {
      wo = {
        winhighlight = Snacks.picker.highlight.winhl("SnacksPicker"),
      },
    },
    wins = {
      source = source_win,
      stdout = stdout_win,
      asm = asm_win,
    },
    hidden = opts.hidden,
    on_update = function()
      update_titles()
    end,
    layout = {
      backdrop = false,
    },
  }))
  resolved_layout = layout
  attach(layout)
  layout:show()
end

-- open_scratch_run("cpp")

return M
