local Snacks = require("snacks")
local misc_util = require("util.misc")
local lazy = require("bufferline.lazy")
local state = lazy.require("bufferline.state") ---@module "bufferline.state"
local utils = lazy.require("bufferline.utils") ---@module "bufferline.utils"
local config = lazy.require("bufferline.config")
local ui = lazy.require("bufferline.ui") ---@module "bufferline.ui"

local M = {}
M.bm_file_to_idx = nil

local uv = vim.uv or vim.loop

---@class snacks.buffer_mngr.File
---@field file string full path to the scratch buffer
---@field stat uv.fs_stat.result File stat result
---@field name string name of the scratch buffer
---@field ft string file type
---@field icon? string icon for the file type
---@field cwd? string current working directory
---@field branch? string Git branch
---@field count? number vim.v.count1 used to open the buffer

---@class snacks.scratch.Config
---@field win? snacks.win.Config scratch window
---@field template? string template for new buffers
---@field file? string scratch file path. You probably don't need to set this.
---@field ft? string|fun():string the filetype of the scratch buffer
local defaults = {
  name = "BufferManager",
  ft = vim.bo.filetype,
  ---@type string|string[]?
  icon = nil, -- `icon|{icon, icon_hl}`. defaults to the filetype icon
  root = vim.fn.stdpath("data") .. "/buffer_mngr",
  autowrite = true, -- automatically write when the buffer is hidden
  -- unique key for the scratch file is based on:
  -- * name
  -- * ft
  -- * vim.v.count1 (useful for keymaps)
  -- * cwd (optional)
  -- * branch (optional)
  filekey = {
    cwd = true, -- use current working directory
    branch = true, -- use current branch name
    count = true, -- use vim.v.count1
  },
  win = { style = "bufman" },
}

Snacks.config.style("bufman", {
  width = 100,
  height = 30,
  bo = { buftype = "", buflisted = false, bufhidden = "hide", swapfile = false },
  minimal = false,
  noautocmd = false,
  -- position = "right",
  zindex = 20,
  wo = { winhighlight = "NormalFloat:Normal" },
  border = "rounded",
  title_pos = "center",
  footer_pos = "center",
})

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
  if
    M.bm_file_to_idx[path_formatter(buffer_a.path)] == nil or M.bm_file_to_idx[path_formatter(buffer_b.path)] == nil
  then
    return false
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

  M.bm_file_to_idx = open_missing_buffers(elements, filtered_buf_mngr_files)
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

--- Open a buffer manager buffer with the given options.
--- If a window is already open with the same buffer,
--- it will be closed instead.
---@param opts? snacks.scratch.Config
function M.open(opts)
  opts = Snacks.config.get("bufman", defaults, opts)
  local ft = "buffer_mngr"

  opts.win = Snacks.win.resolve("bufman", opts.win, { show = false })
  opts.win.bo = opts.win.bo or {}
  opts.win.bo.filetype = ft

  local file = opts.file
  if not file then
    local branch = ""
    if opts.filekey.branch and uv.fs_stat(".git") then
      local ret = vim.fn.systemlist("git branch --show-current")[1]
      if vim.v.shell_error == 0 then
        branch = ret
      end
    end

    local filekey = {
      opts.filekey.count and tostring(vim.v.count1) or "",
      opts.icon or "",
      opts.name:gsub("|", " "),
      opts.filekey.cwd and vim.fs.normalize(assert(uv.cwd())) or "",
      branch,
    }

    vim.fn.mkdir(opts.root, "p")
    local fname = Snacks.util.file_encode(table.concat(filekey, "|") .. "." .. ft)
    file = vim.fs.normalize(opts.root .. "/" .. fname)
  end

  -- local icon, icon_hl = unpack(type(opts.icon) == "table" and opts.icon or { opts.icon, nil })
  local icon = ""
  local icon_hl = nil
  ---@cast icon string
  -- if not icon then
  --   icon, icon_hl = Snacks.util.icon(ft, "filetype")
  -- end
  opts.win.title = {
    { " " },
    { icon .. string.rep(" ", 2 - vim.api.nvim_strwidth(icon)), icon_hl },
    { " " },
    { opts.name .. (vim.v.count1 > 1 and " " .. vim.v.count1 or "") },
    { " " },
  }
  for _, t in ipairs(opts.win.title) do
    t[2] = t[2] or "BufferManagerTitle"
  end

  -- local is_new = not uv.fs_stat(file)
  local mngr_buf = vim.fn.bufadd(file)

  local closed = false
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == mngr_buf then
      vim.schedule(function()
        vim.api.nvim_win_call(win, function()
          vim.cmd([[close]])
        end)
      end)
      closed = true
    end
  end
  if closed then
    return
  end

  if not vim.api.nvim_buf_is_loaded(mngr_buf) then
    vim.fn.bufload(mngr_buf)
  end

  local elements = state.components
  -- fill buffer with names
  if next(elements) == nil then
    Snacks.notify.warn("No files to manage")
    return
  end
  local contents = {}
  for index, buf in ipairs(elements) do
    contents[index] = path_formatter(buf.path)
  end
  vim.api.nvim_buf_set_lines(mngr_buf, 0, -1, false, contents)

  local function open_file()
    local filename = vim.fn.expand("<cfile>")
    vim.cmd("silent! write")
    vim.cmd([[close]])
    misc_util.open_file(filename)
  end
  opts.win.keys = opts.win.keys or {}
  opts.win.keys.reset = { "<cr>", open_file, desc = "Open file" }

  opts.win.buf = mngr_buf
  local ret = Snacks.win(opts.win)
  ret.opts.footer = {}
  table.sort(ret.keys, function(a, b)
    return a[1] < b[1]
  end)
  for _, key in ipairs(ret.keys) do
    local keymap = vim.fn.keytrans(vim.keycode(key[1]))
    table.insert(ret.opts.footer, { " " })
    table.insert(ret.opts.footer, { " " .. keymap .. " ", "BufferManagerKey" })
    table.insert(ret.opts.footer, { " " .. (key.desc or keymap) .. " ", "BufferManagerDesc" })
  end
  table.insert(ret.opts.footer, { " " })

  for _, t in ipairs(ret.opts.footer) do
    t[2] = t[2] or "BufferManagerFooter"
  end

  vim.api.nvim_create_autocmd("BufHidden", {
    group = vim.api.nvim_create_augroup("buffer_mngr_autowrite_" .. mngr_buf, { clear = true }),
    buffer = mngr_buf,
    callback = function()
      vim.cmd("silent! write")
      local files = get_contents(mngr_buf)
      update_bufferline(files)
    end,
  })

  return ret:show()
end

return M
