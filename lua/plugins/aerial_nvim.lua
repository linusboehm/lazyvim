-- local Config = require("lazyvim.config")
local misc_util = require("util.misc")

local function find_tokens(bufnr, tokens)
  local ret_lines = {}
  local ret_tokens = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for lineno, line in ipairs(lines) do
    for _, token in pairs(tokens) do
      if string.match(line, "^%s*" .. token .. ":") then
        table.insert(ret_lines, lineno)
        table.insert(ret_tokens, token)
      end
    end
  end
  return ret_lines, ret_tokens
end

local function add_custom_token(items, level, parent, curr_line, acc_spec)
  local acc_range = {
    lnum = curr_line,
    end_lnum = curr_line,
    col = 1,
    end_col = 1,
  }
  ---@type aerial.Symbol
  local access_specifier_item = {
    kind = "Enum",
    name = acc_spec,
    level = level,
    parent = parent,
    selection_range = acc_range,
    scope = nil,
  }
  for k, v in pairs(acc_range) do
    access_specifier_item[k] = v
  end
  -- dump(access_specifier_item)
  table.insert(items, access_specifier_item)
  table.insert(parent.children, access_specifier_item)
end

local function _process_symbols(bufnr, items, token_lines, tokens)
  for _, item in ipairs(items) do
    if item.children then
      _process_symbols(bufnr, item.children, token_lines, tokens)
    end

    local added = {}
    for idx, curr_line in ipairs(token_lines) do
      -- add access specifier if its before the end of last seen class
      if curr_line > item.lnum and curr_line < item.end_lnum then
        local new_level = item.level + 1
        add_custom_token(item.children, new_level, item, curr_line, tokens[idx])
        table.insert(added, idx)
      end
    end

    if #added > 0 then
      -- sort children
      table.sort(item.children, function(a, b)
        a = a.selection_range and a.selection_range or a
        b = b.selection_range and b.selection_range or b
        if a.lnum == b.lnum then
          return a.col < b.col
        else
          return a.lnum < b.lnum
        end
      end)
      -- remove added keywords
      for i = #added, 1, -1 do
        local idx = added[i]
        table.remove(tokens, idx)
        table.remove(token_lines, idx)
      end
    end
  end
end

local post_proccess = function(bufnr, items, ctx)
  local token_lines, tokens = find_tokens(bufnr, { "public", "private", "protected" })
  _process_symbols(bufnr, items, token_lines, tokens)
  return items
end

return {
  desc = "Aerial Symbol Browser",
  {
    -- "stevearc/aerial.nvim",
    "linusboehm/aerial.nvim",
    -- branch = "my_features",
    event = "LazyFile",
    opts = function()
      -- local icons = vim.deepcopy(Config.icons.kinds)

      -- -- HACK: fix lua's weird choice for `Package` for control
      -- -- structures like if/else/for/etc.
      -- icons.lua = { Package = icons.Control }

      -- ---@type table<string, string[]>|false
      -- local filter_kind = false
      -- if Config.kind_filter then
      --   filter_kind = assert(vim.deepcopy(Config.kind_filter))
      --   filter_kind._ = filter_kind.default
      --   filter_kind.default = nil
      -- end

      local opts = {
        -- attach_mode = "global",
        backends = { "lsp", "treesitter", "markdown", "man" },
        show_guides = true,
        layout = {
          default_direction = "prefer_left",
          resize_to_content = true,
          -- win_opts = {
          --   winhl = "Normal:NormalFloat,FloatBorder:NormalFloat,SignColumn:SignColumnSB",
          --   signcolumn = "yes",
          --   statuscolumn = " ",
          -- },
        },
        ignore = {
          diff_windows = false,
          --   unlisted_buffers = false,
          --   buftypes = false,
          --   wintypes = false,
        },
        -- icons = icons,
        -- filter_kind = filter_kind,
        -- stylua: ignore
        guides = {
          mid_item = "├╴",
          last_item = "└╴",
          nested_top = "│ ",
          whitespace = "  ",
        },
        post_add_all_symbols = function(bufnr, items, ctx)
          return post_proccess(bufnr, items, ctx)
        end,
      }
      return opts
    end,
    keys = {
      { "<leader>a", "<cmd>AerialToggle<cr>", desc = "Aerial (Symbols)" },
    },
  },

  -- Telescope integration
  {
    "nvim-telescope/telescope.nvim",
    optional = true,
    opts = function()
      LazyVim.on_load("telescope.nvim", function()
        require("telescope").load_extension("aerial")
      end)
    end,
    keys = {
      {
        "<leader>ss",
        "<cmd>Telescope aerial<cr>",
        desc = "Goto Symbol (Aerial)",
      },
    },
  },
}
