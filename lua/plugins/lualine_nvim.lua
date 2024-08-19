local icons = require("lazyvim.config").icons

local git_diff = function(is_active)
  if not is_active then
    return {}
  end
  return {
    "diff",
    symbols = {
      added = icons.git.added,
      modified = icons.git.modified,
      removed = icons.git.removed,
    },
    padding = { left = 0, right = 1 },
    separator = "‖",
  }
end

local recording = function(is_active)
  if not is_active then
    return {}
  end
  return {
    require("noice").api.status.mode.get,
    cond = require("noice").api.status.mode.has,
    color = { fg = "#ff9e64" },
  }
end

local section_settings = function(is_active)
  return {
    lualine_a = not is_active and {} or {"mode"},
    lualine_b = not is_active and {} or {
      -- { function() return "" end, separator = "", padding = { left = 1, right = 0 }, },
      {
        "branch",
        separator = "",
        icon = "",
        fmt = function(str)
          -- truncate long branches
          if #str <= 10 then
            return str
          end
          local ret_str = ""
          local last_substr = ""
          for substr in string.gmatch(str, "[^/]+") do
            last_substr = substr
            ret_str = ret_str .. string.sub(substr, 1, 5) .. "../"
          end
          ret_str = ret_str:sub(1, -4) .. string.sub(last_substr, 6, 9) .. ".."
          return ret_str
        end,
      },
      git_diff(is_active),
    },
    lualine_c = {
      {
        "filetype",
        separator = "",
        icon_only = true,
        padding = { left = 1, right = 0 },
      },
      {
        "filename",
        path = 1,
        -- symbols = { modified = icons.git.modified, readonly = "", unnamed = "" },
        symbols = { modified = "" },
        separator = "",
        padding = { left = 1, right = 0 },
        color = function()
          if not is_active then
            return {}
          end
          local buf_nr = vim.api.nvim_get_current_buf()
          if vim.api.nvim_buf_get_option(buf_nr, "modified") then
            return { fg = "#ff9e64" }
          else
            return { fg = "#73daca" }
          end
        end,
      },
      {
        function()
          local buf_nr = vim.api.nvim_get_current_buf()
          if not vim.api.nvim_buf_get_option(buf_nr, "modified") then
            return ""
          end
          local undo_tree = vim.fn.undotree()
          local entries = undo_tree.entries
          local save_last = undo_tree.save_last
          if #entries == 0 then
            return ""
          end
          local newhead
          local curhead
          local save
          local found_save = false
          for key, entry in ipairs(entries) do
            if entry.newhead then
              newhead = key
            end
            if entry.save then
              save = key
            end
            if entry.curhead then
              curhead = key - 1
            end
            if entry.save == save_last then
              found_save = true
            end
          end
          if not found_save then
            return "[?]"
          end -- last save is in alternate tree branch
          if save == nil then
            save = 0
          end
          if newhead == nil then
            newhead = 0
          end
          local head
          if curhead then
            head = curhead
          else
            head = newhead
          end
          local mods = head - save
          return "[" .. mods .. "]"
        end,
        padding = { left = 0, right = 0 },
        color = function()
          if not is_active then
            return {}
          end
          local buf_nr = vim.api.nvim_get_current_buf()
          if vim.api.nvim_buf_get_option(buf_nr, "modified") then
            return { fg = "#ff9e64" }
          else
            return { fg = "#73daca" }
          end
        end,
      },
    },
    lualine_x = not is_active and {} or {
      { "searchcount", separator = "‖" },
      recording(is_active),
    },
    lualine_y = not is_active and {} or {
      {
        function()
          return ""
        end,
        separator = "",
      },
      { "progress", separator = " ", padding = { left = 0, right = 0 } },
      { "location", padding = { left = 0, right = 1 } },
    },
    -- lualine_z = { function() return "⏱ " .. os.date("%R") end, },
    lualine_z = not is_active and {} or {
      function()
        return " " .. os.date("%R")
      end,
    },
  }
end
return {
  -- -- the opts function can also be used to change the default opts:
  -- {
  --   "nvim-lualine/lualine.nvim",
  --   event = "VeryLazy",
  --   opts = function(_, opts)
  --     table.insert(opts.sections.lualine_x, "😄")
  --   end,
  -- },

  -- or you can return new options to override all the defaults
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "auto",
        -- -- check filetype with `:lua vim.print(vim.bo.filetype)`
        -- disabled_filetypes = { statusline = { "DiffviewFiles", "aerial", "dashboard", "alpha", "toggleterm" } },
        -- ignore_focus = { "neo-tree", "aerial", "toggleterm" },
      },
      sections = section_settings(true),
      inactive_sections = section_settings(false),
      extensions = { "neo-tree", "lazy", "toggleterm" },
    },
  },
}
