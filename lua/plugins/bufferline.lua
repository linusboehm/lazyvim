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
    -- { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete buffers to the left" },
    { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
    { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
    { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    { "<leader>bh", "<Cmd>BufferLineMovePrev<CR>", desc = "move current buffer backwards" },
    { "<leader>bl", "<Cmd>BufferLineMoveNext<CR>", desc = "move current buffer forwards" },
    { "<leader>br", false },
  },
  opts = function()
    local function get_hl_color(name, attr)
      local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
      if hl and hl[attr] then
        return string.format("#%06x", hl[attr])
      end
    end

    local function pick_hl_color(attr, groups)
      for _, group in ipairs(groups) do
        local color = get_hl_color(group, attr)
        if color then
          return color
        end
      end
    end

    local function blend(fg, bg, alpha)
      if not fg or not bg then
        return fg
      end

      local function rgb(color)
        color = color:gsub("#", "")
        return tonumber(color:sub(1, 2), 16), tonumber(color:sub(3, 4), 16), tonumber(color:sub(5, 6), 16)
      end

      local fr, fg_, fb = rgb(fg)
      local br, bg_, bb = rgb(bg)
      local function channel(front, back)
        return math.floor((alpha * front) + ((1 - alpha) * back) + 0.5)
      end

      return string.format("#%02x%02x%02x", channel(fr, br), channel(fg_, bg_), channel(fb, bb))
    end

    -- Use only colors from the active colorscheme so this adapts when the theme changes.
    local function get_visible_bg()
      return pick_hl_color("bg", { "Normal", "TabLine", "StatusLine" })
    end

    local visible_bg = get_visible_bg()
    local current_buffer_fg = pick_hl_color("fg", { "FloatBorder", "Keyword", "PreProc", "Normal" })
    local visible_buffer_fg = blend(current_buffer_fg, visible_bg, 0.65)
      or pick_hl_color("fg", { "StatusLine", "Comment", "Normal" })
    local inactive_buffer_fg = pick_hl_color("fg", { "TabLine", "Comment", "StatusLineNC", "Normal" })

    local function filename_hl(fg)
      return {
        fg = fg,
        sp = fg,
      }
    end

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
        buffer = filename_hl(inactive_buffer_fg),
        error = filename_hl(inactive_buffer_fg),
        warning = filename_hl(inactive_buffer_fg),
        info = filename_hl(inactive_buffer_fg),
        hint = filename_hl(inactive_buffer_fg),
        buffer_selected = filename_hl(current_buffer_fg),
        numbers_selected = filename_hl(current_buffer_fg),
        error_selected = filename_hl(current_buffer_fg),
        warning_selected = filename_hl(current_buffer_fg),
        info_selected = filename_hl(current_buffer_fg),
        hint_selected = filename_hl(current_buffer_fg),
        buffer_visible = {
          fg = visible_buffer_fg,
          sp = visible_buffer_fg,
          bg = visible_bg,
        },
        numbers_visible = {
          fg = visible_buffer_fg,
          bg = visible_bg,
        },
        diagnostic_visible = {
          bg = visible_bg,
        },
        error_visible = {
          fg = visible_buffer_fg,
          sp = visible_buffer_fg,
          bg = visible_bg,
        },
        error_diagnostic_visible = {
          bg = visible_bg,
        },
        warning_visible = {
          fg = visible_buffer_fg,
          sp = visible_buffer_fg,
          bg = visible_bg,
        },
        warning_diagnostic_visible = {
          bg = visible_bg,
        },
        info_visible = {
          fg = visible_buffer_fg,
          sp = visible_buffer_fg,
          bg = visible_bg,
        },
        info_diagnostic_visible = {
          bg = visible_bg,
        },
        hint_visible = {
          fg = visible_buffer_fg,
          sp = visible_buffer_fg,
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
