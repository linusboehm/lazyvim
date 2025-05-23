local Snacks = require("snacks")
local misc_util = require("util.misc")
local lazy = require("bufferline.lazy")
local state = lazy.require("bufferline.state") ---@module "bufferline.state"
local utils = lazy.require("bufferline.utils") ---@module "bufferline.utils"
local config = lazy.require("bufferline.config")
local ui = lazy.require("bufferline.ui") ---@module "bufferline.ui"
local closed = true
local last_print_time = 0

local M = {}
M.bm_file_to_idx = nil

local uv = vim.uv or vim.loop

---@type snacks.win
local buf_win = nil

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

local default_actions = {
  open_file = function()
    local filename = vim.fn.expand("<cfile>")
    closed = true
    buf_win:close()
    misc_util.open_file(filename)
  end,
  close = function()
    norm(function()
      closed = true
      buf_win:close()
    end)
  end,
  -- avante_add = function()
  --   -- Open sidebar first (only once)
  --   local sidebar = require("avante").get()
  --   local open = sidebar:is_open()
  --   local avante_utils = require("avante.utils")
  --   -- ensure avante sidebar is open
  --   if not open then
  --     require("avante.api").ask()
  --     sidebar = require("avante").get()
  --   end
  --   local start_line = vim.api.nvim_buf_get_mark(0, "<")[1]
  --   local end_line = vim.api.nvim_buf_get_mark(0, ">")[1]
  --   Snacks.notify.info("Adding " .. start_line .. " to " .. end_line)
  --   local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  --   local git_root = Snacks.git.get_root()
  --   for i, line in ipairs(lines) do
  --     lines[i] = line:gsub(git_root .. "/", "")
  --     Snacks.notify.info("Adding " .. line)
  --   end
  --
  --   local paths = sidebar.file_selector:get_selected_filepaths()
  --   Snacks.notify.info("comparing " .. vim.inspect(paths))
  --   for _, path in pairs(paths) do
  --     if not vim.tbl_contains(lines, path) then
  --       sidebar.file_selector:remove_selected_file(path)
  --     end
  --   end
  -- end,
}

---@type snacks.win.Config
local window_opts = {
  bo = { buftype = "", buflisted = false, bufhidden = "hide", swapfile = false },
  wo = { winhighlight = "NormalFloat:Normal" },
  border = "rounded",
  title_pos = "center",
  minimal = false,
  width = 100,
  height = 30,
  footer_pos = "center",
  title = "  BufferManager ",
  keys = {
    ["<cr>"] = { "open_file", mode = { "i", "n" }, desc = "open file" },
    ["q"] = "close",
    -- ["a"] = { "avante_add", mode = { "v" }, desc = "avante add" },
  },
  fixbuf = true,
  actions = default_actions,
}

local function path_formatter(path)
  return vim.fn.fnamemodify(path, ":p:.")
end

---@param bufnr number
local function get_contents(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
  local indices = {}

  for _, line in pairs(lines) do
    table.insert(indices, line)
  end

  return indices
end

local function open_missing_buffers(elements, files)
  -- Create a lookup table buf -> index
  local buf_to_index = {}
  for index, name in ipairs(elements) do
    buf_to_index[path_formatter(name.path)] = index
  end

  -- remove deleted elements
  for _, file in ipairs(files) do
    if not buf_to_index[path_formatter(file)] then
      misc_util.open_file(file)
    end
  end
end

local function close_buffers_not_in_list(elements, files)
  local commands = lazy.require("bufferline.commands")
  -- Create a lookup table buf mngr file -> index
  local file_to_idx = {}
  for index, name in ipairs(files) do
    file_to_idx[name] = index
  end

  -- remove deleted elements
  for _, item in ipairs(elements) do
    if not file_to_idx[path_formatter(item.path)] then
      commands.unpin_and_close(item.id)
    end
  end
  return file_to_idx
end

M.sort_by_buffer_mngr = function(buffer_a, buffer_b)
  if M.bm_file_to_idx == nil then
    return false
  end
  if M.bm_file_to_idx[path_formatter(buffer_a.path)] == nil then
    return false
  end
  if M.bm_file_to_idx[path_formatter(buffer_b.path)] == nil then
    return true
  end
  return M.bm_file_to_idx[path_formatter(buffer_a.path)] < M.bm_file_to_idx[path_formatter(buffer_b.path)]
end

local function update_bufferline(buf_mngr_files)
  if next(buf_mngr_files) == nil then
    return
  end

  local elements = state.components

  -- remove invalid entries from buf_mngr_files
  local filtered_buf_mngr_files = {}
  for _, name in ipairs(buf_mngr_files) do
    -- only use if file exists
    if vim.fn.findfile(name, "**") ~= "" then
      table.insert(filtered_buf_mngr_files, name)
    end
  end

  open_missing_buffers(elements, filtered_buf_mngr_files)
  M.bm_file_to_idx = close_buffers_not_in_list(elements, filtered_buf_mngr_files)

  table.sort(elements, M.sort_by_buffer_mngr)
  for index, buf in ipairs(elements) do
    buf.ordinal = index
  end
  state.custom_sort = utils.get_ids(state.components)
  local opts = config.options
  if opts.persist_buffer_sort then
    utils.save_positions(state.custom_sort)
  end
  ui.refresh()
end

---@param filetype? string
---@param subdir? string
local get_file = function(filetype, subdir)
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

  local root = vim.fn.stdpath("data") .. "/" .. subdir
  local fname = Snacks.util.file_encode(table.concat(filekey, "|") .. "." .. filetype)
  local file = root .. "/" .. fname
  file = svim.fs.normalize(file)
  return file
end

local attach = function()
  -- close when we leave window
  vim.api.nvim_create_autocmd("WinEnter", {
    desc = "Reset bufhidden when entering a preview buffer",
    group = vim.api.nvim_create_augroup("snacks_run_winenter_" .. buf_win.buf, { clear = true }),
    pattern = "*",
    callback = function()
      if closed then
        return
      end
      local current = vim.api.nvim_get_current_win()
      if current ~= buf_win.win then
        vim.schedule(function()
          norm(function()
            closed = true
            buf_win:close()
          end)
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufHidden", {
    group = vim.api.nvim_create_augroup("snacks_run_autowrite_" .. buf_win.buf, { clear = true }),
    buffer = buf_win.buf,
    callback = function(ev)
      vim.api.nvim_buf_call(ev.buf, function()
        vim.cmd("silent! write")
        local files = get_contents(buf_win.buf)
        update_bufferline(files)
      end)
    end,
  })

  vim.api.nvim_create_autocmd({ "BufDelete" }, {
    group = vim.api.nvim_create_augroup("snacks_run_del_" .. buf_win.buf, { clear = true }),
    callback = function(args)
      local bufnr = args.buf
      local filename = vim.api.nvim_buf_get_name(bufnr)
      local filtered = {}
      for file, value in pairs(M.bm_file_to_idx) do
        if file ~= path_formatter(filename) then
          filtered[file] = value
        end
      end
      M.bm_file_to_idx = filtered
    end,
  })
end

--- Open a buffer manager buffer with the given options.
--- If a window is already open with the same buffer,
--- it will be closed instead.
function M.open()
  -- local is_new = not uv.fs_stat(file)

  local curr_path = path_formatter(vim.api.nvim_buf_get_name(0))

  local mngr_buf = vim.fn.bufadd(get_file("buf_man", "buffer_mngr"))
  if not vim.api.nvim_buf_is_loaded(mngr_buf) then
    vim.fn.bufload(mngr_buf)
  end

  if not closed then
    closed = true
    buf_win:close()
    return
  end

  local elements = state.components
  -- fill buffer with names
  if next(elements) == nil then
    Snacks.notify.warn("No files to manage")
    return
  end
  local contents = {}
  local file_idx = 0
  for index, buf in ipairs(elements) do
    contents[index] = path_formatter(buf.path)
    if contents[index] == curr_path then
      file_idx = index
    end
  end
  vim.api.nvim_buf_set_lines(mngr_buf, 0, -1, false, contents)

  window_opts.buf = mngr_buf
  window_opts.on_win = function(win)
    vim.api.nvim_win_set_cursor(win.win, { file_idx, 0 })
  end
  buf_win = Snacks.win(window_opts)

  buf_win.opts.footer = {}
  table.sort(buf_win.keys, function(a, b)
    return a[1] < b[1]
  end)
  for _, key in ipairs(buf_win.keys) do
    local keymap = vim.fn.keytrans(vim.keycode(key[1]))
    table.insert(buf_win.opts.footer, { " " })
    table.insert(buf_win.opts.footer, { " " .. keymap .. " ", "SnacksScratchKey" })
    table.insert(buf_win.opts.footer, { " " .. (key.desc or keymap) .. " ", "SnacksScratchDesc" })
  end
  table.insert(buf_win.opts.footer, { " " })

  for _, t in ipairs(buf_win.opts.footer) do
    t[2] = t[2] or "BufferManagerFooter"
  end

  attach()
  closed = false
  return buf_win:show()
end

-- update the ordering whenever a new buffer is opened
vim.api.nvim_create_autocmd("BufRead", {
  pattern = "*",
  callback = function()
    -- need to wait until the bufferline is updated to have the latest state.components
    vim.defer_fn(function()
      local commands = lazy.require("bufferline.commands")
      local _, element = commands.get_current_element_index(state, { include_hidden = true })
      -- ignore buffers that are not in the bufferline
      if not element or not element.group or not buf_win then
        return
      end
      Snacks.notify.info("updating bufferline order")

      local elements = state.components
      table.sort(elements, M.sort_by_buffer_mngr)
      for index, buf in ipairs(elements) do
        buf.ordinal = index
        M.bm_file_to_idx[path_formatter(buf.path)] = index
      end
      state.custom_sort = utils.get_ids(state.components)
      local opts = config.options
      if opts.persist_buffer_sort then
        utils.save_positions(state.custom_sort)
      end
      ui.refresh()
    end, 20)
  end,
})

return M
