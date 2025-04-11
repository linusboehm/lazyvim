local function get_open_buffer_paths()
  local buffers = {}
  -- Loop through all buffer numbers
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    -- Check if buffer is listed (appears in :ls) and has a real file
    if vim.fn.buflisted(bufnr) == 1 then
      local bufname = vim.api.nvim_buf_get_name(bufnr)

      -- Only include buffers that have a filename
      if bufname and bufname ~= "" and vim.fn.filereadable(bufname) == 1 then
        -- Get absolute path
        local path = vim.fn.fnamemodify(bufname, ":p")
        table.insert(buffers, path)
      end
    end
  end
  return buffers
end

return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  opts = {
    file_selector = { provider = "snacks" },
    provider = "copilot",
    copilot = {
      model = "claude-3.7-sonnet",
      -- timeout = 30000, -- increase for reasoning models
      -- temperature = 0,
      max_tokens = 8192,
    },
  },
  build = "make",
  keys = {
    {
      "<leader>ab",
      function()
        local filepaths = get_open_buffer_paths()

        -- Open sidebar first (only once)
        local sidebar = require("avante").get()
        local open = sidebar:is_open()
        -- ensure avante sidebar is open
        if not open then
          require("avante.api").ask()
          sidebar = require("avante").get()
        end

        -- Add each file to sidebar
        Snacks.notify.info("Adding " .. #filepaths .. " files to sidebar")
        for _, filepath in ipairs(filepaths) do
          local relative_path = require("avante.utils").relative_path(filepath)
          sidebar.file_selector:add_selected_file(relative_path)
        end
      end,
      desc = "Avante add open buffers",
    },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "zbirenbaum/copilot.lua",
  },
}
