local lazy = require("bufferline.lazy")
local state = lazy.require("bufferline.state") ---@module "bufferline.state"
local ui = lazy.require("bufferline.ui") ---@module "bufferline.ui"
local utils = lazy.require("bufferline.utils") ---@module "bufferline.utils"
local config = lazy.require("bufferline.config")
local Snacks = require("snacks")

local augroup = vim.api.nvim_create_augroup
local buf_mngr_group = augroup("BufMngrGroup", {})

local bm_file_to_idx = nil

local function path_formatter(path)
  return vim.fn.fnamemodify(path, ":p:.")
end

local sort_by = function(buffer_a, buffer_b)
  if bm_file_to_idx == nil then
    return false
  end
  if bm_file_to_idx[path_formatter(buffer_a.path)] == nil or bm_file_to_idx[path_formatter(buffer_b.path)] == nil then
    return false
  end
  return bm_file_to_idx[path_formatter(buffer_a.path)] < bm_file_to_idx[path_formatter(buffer_b.path)]
end

local function get_file_path()
  local filename = (vim.fn.getcwd() .. "_buffer_manager.json"):gsub("/", "_")
  local nvim_state_dir = vim.fn.stdpath("state")
  return nvim_state_dir .. "/sessions/" .. filename
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

local function update_bufferline(elements, buf_mngr_files)
  if next(buf_mngr_files) == nil then
    return
  end

  -- Create a lookup table path -> index
  local buffer_path_to_idx = {}
  for index, buf in ipairs(elements) do
    buffer_path_to_idx[path_formatter(buf.path)] = index
  end

  -- remove invalid entries from buf_mngr_files
  local filtered_buf_mngr_files = {}
  for _, name in ipairs(buf_mngr_files) do
    if buffer_path_to_idx[name] then
      table.insert(filtered_buf_mngr_files, name)
    end
  end

  bm_file_to_idx = close_buffers_not_in_list(elements, filtered_buf_mngr_files)

  local file = io.open(get_file_path(), "w")
  if file == nil then
    vim.print("unable to open file: " .. get_file_path())
    return false
  end
  local json = vim.fn.json_encode(bm_file_to_idx)
  file:write(json)
  file:close()
  Snacks.notify.info("dumped to file: " .. get_file_path())
  table.sort(elements, sort_by)
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

local function toggle_buf_mngr(buf_mngr)
  local elements = state.components
  if next(elements) == nil then
    return utils.notify("Unable to find elements to manage, sorry", "warn")
  end
  if buf_mngr.win_id ~= nil then
    local buf_mngr_files = buf_mngr:close_menu()
    update_bufferline(elements, buf_mngr_files)
  else
    buf_mngr:open_quick_menu(elements)
  end
end

local function setup_autocmds_and_keymaps(buf_mngr, bufnr)
  vim.api.nvim_set_option_value("filetype", "buf_mngr", {
    buf = bufnr,
  })
  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = bufnr })
  vim.keymap.set("n", "q", function()
    toggle_buf_mngr(buf_mngr)
  end, { buffer = bufnr, silent = true })

  vim.keymap.set("n", "<Esc>", function()
    toggle_buf_mngr(buf_mngr)
  end, { buffer = bufnr, silent = true })

  vim.api.nvim_create_autocmd({ "BufLeave" }, {
    group = buf_mngr_group,
    buffer = bufnr,
    callback = function()
      toggle_buf_mngr(buf_mngr)
    end,
  })
end

---@class bufferline.BuffersUi
local BuffersUi = {}

BuffersUi.__index = BuffersUi

---@return bufferline.BuffersUi
function BuffersUi:new()
  return setmetatable({
    win_id = nil,
    bufnr = nil,
  }, self)
end

function BuffersUi:close_menu()
  if self.closing then
    return {}
  end
  local files = get_contents(self.bufnr)

  self.closing = true
  if self.bufnr ~= nil and vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
  end

  if self.win_id ~= nil and vim.api.nvim_win_is_valid(self.win_id) then
    vim.api.nvim_win_close(self.win_id, true)
  end

  self.win_id = nil
  self.bufnr = nil

  self.closing = false
  return files
end

function BuffersUi:_create_window()
  local win = vim.api.nvim_list_uis()

  local width = 20

  if #win > 0 then
    width = math.floor(win[1].width * 0.5)
  end

  local height = 20
  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    title = "Manage Buffers",
    title_pos = "left",
    row = math.floor(((vim.o.lines - height) / 2) - 1),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = "minimal",
    border = "single",
  })

  if win_id == 0 then
    self.bufnr = bufnr
    self:close_menu()
  end

  setup_autocmds_and_keymaps(self, bufnr)

  self.win_id = win_id
  vim.api.nvim_set_option_value("number", true, {
    win = win_id,
  })

  return win_id, bufnr
end

--- @param elements bufferline.TabElement[]
function BuffersUi:open_quick_menu(elements)
  local win_id, bufnr = self:_create_window()

  self.win_id = win_id
  self.bufnr = bufnr

  local contents = {}

  for index, buf in ipairs(elements) do
    contents[index] = path_formatter(buf.path)
  end

  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, contents)
end

local buf_mngr = BuffersUi:new()

local function read_json_file()
  local filepath = get_file_path()
  -- Open the file in read mode
  local file = io.open(filepath, "r")
  if not file then
    error("Could not open file: " .. filepath)
    return nil
  end

  -- Read the entire file content
  local content = file:read("*a")
  file:close()

  -- Decode the JSON content into a Lua table
  local decoded_content = vim.fn.json_decode(content)
  return decoded_content
end

return {
  -- "linusboehm/bufferline.nvim",
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  keys = {
    { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
    { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
    { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete other buffers" },
    -- { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete buffers to the right" },
    { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete buffers to the left" },
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
    { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    { "<leader>bh", "<Cmd>BufferLineMovePrev<CR>", desc = "move current buffer backwards" },
    { "<leader>bl", "<Cmd>BufferLineMoveNext<CR>", desc = "move current buffer forwards" },
    {
      "<leader>bm",
      function()
        toggle_buf_mngr(buf_mngr)
      end,
      desc = "manage buffers",
    },
    { "<leader>br", false },
  },
  opts = {
    options = {
      -- stylua: ignore
      separator_style = "slope",
      close_command = function(n)
        Snacks.bufdelete(n)
      end,
      diagnostics = "nvim_lsp",
      always_show_bufferline = false,
      diagnostics_indicator = function(_, _, diag)
        local icons = LazyVim.config.icons.diagnostics
        local ret = (diag.error and icons.Error .. diag.error .. " " or "")
          .. (diag.warning and icons.Warn .. diag.warning or "")
        return vim.trim(ret)
      end,
      offsets = {
        {
          filetype = "neo-tree",
          text = "Neo-tree",
          highlight = "Directory",
          text_align = "left",
        },
      },
      ---@param opts bufferline.IconFetcherOpts
      get_element_icon = function(opts)
        return LazyVim.config.icons.ft[opts.filetype]
      end,
    },
  },
}
