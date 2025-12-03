local Snacks = require("snacks")
-- local buff_mngr = require("util.buffer_manager")

return {
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
    { "<leader>br", false },
  },
  opts = function()
    -- Get a sensible background color from the colorscheme
    local function get_visible_bg()
      -- -- Try CursorLine background first (good for "visible but inactive" state)
      -- local cursorline = vim.api.nvim_get_hl(0, { name = "CursorLine" })
      -- if cursorline.bg then
      --   return string.format("#%06x", cursorline.bg)
      -- end
      -- Fallback to Visual background
      local visual = vim.api.nvim_get_hl(0, { name = "Normal" })
      if visual.bg then
        return string.format("#%06x", visual.bg)
      end
      -- Last resort fallback
      return "#3e4451"
    end

    local visible_bg = get_visible_bg()

    return {
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
        -- offsets = {
        --   {
        --     filetype = "neo-tree",
        --     text = "Neo-tree",
        --     highlight = "Directory",
        --     text_align = "left",
        --   },
        -- },
        persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
        -- sort_by = function(buffer_a, buffer_b)
        --   -- if require("util.buffer_manager").bm_file_to_idx ~= nil then
        --   --   Snacks.notify.info("In custom sort function")
        --   -- end
        --   Snacks.notify.info("In custom sort function2")
        --   -- return buff_mngr.sort_by_buffer_mngr(buffer_a, buffer_b)
        --   local modified_a = vim.fn.getftime(buffer_a.path)
        --   local modified_b = vim.fn.getftime(buffer_b.path)
        --   return modified_a > modified_b
        -- end,
        get_element_icon = function(opts)
          return LazyVim.config.icons.ft[opts.filetype]
        end,
      },
      highlights = {
        buffer_visible = {
          bg = visible_bg,
        },
        numbers_visible = {
          bg = visible_bg,
        },
        diagnostic_visible = {
          bg = visible_bg,
        },
        error_visible = {
          bg = visible_bg,
        },
        error_diagnostic_visible = {
          bg = visible_bg,
        },
        warning_visible = {
          bg = visible_bg,
        },
        warning_diagnostic_visible = {
          bg = visible_bg,
        },
        info_visible = {
          bg = visible_bg,
        },
        info_diagnostic_visible = {
          bg = visible_bg,
        },
        hint_visible = {
          bg = visible_bg,
        },
        hint_diagnostic_visible = {
          bg = visible_bg,
        },
        duplicate_visible = {
          bg = visible_bg,
        },
        separator_visible = {
          bg = visible_bg,
        },
        modified_visible = {
          bg = visible_bg,
        },
        close_button_visible = {
          bg = visible_bg,
        },
      },
    }
  end,
}
