-- local Config = require("lazyvim.config")
-- local misc_util = require("util.misc")

local function find_tokens(bufnr, tokens)
  local ret_lines = {}
  local ret_tokens = {}
  local match_ranges = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for lineno, line in ipairs(lines) do
    for _, token in pairs(tokens) do
      local found = string.match(line, "^%s*" .. token .. ":")
      if found then
        table.insert(ret_lines, lineno)
        table.insert(ret_tokens, token)
        table.insert(match_ranges, { #found - #token - 1, #found - 1 })
      end
    end
  end
  return ret_lines, ret_tokens, match_ranges
end

local function add_custom_token(items, level, parent, curr_line, token, match_range)
  local acc_range = {
    lnum = curr_line,
    end_lnum = curr_line,
    col = match_range[1],
    end_col = match_range[2],
  }
  ---@type aerial.Symbol
  local access_specifier_item = {
    kind = "Enum",
    name = token,
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

local function _process_symbols(bufnr, items, token_lines, tokens, match_ranges)
  for _, item in ipairs(items) do
    if item.children then
      _process_symbols(bufnr, item.children, token_lines, tokens, match_ranges)
    end

    local added = {}
    for idx, curr_line in ipairs(token_lines) do
      -- add access specifier if its before the end of last seen class
      if curr_line > item.lnum and curr_line < item.end_lnum then
        local new_level = item.level + 1
        if not item.children then
          item["children"] = {}
        end
        add_custom_token(item.children, new_level, item, curr_line, tokens[idx], match_ranges[idx])
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
        table.remove(match_ranges, idx)
      end
    end
  end
end

local post_proccess = function(bufnr, items, _)
  local token_lines, tokens, match_ranges = find_tokens(bufnr, { "public", "private", "protected" })
  _process_symbols(bufnr, items, token_lines, tokens, match_ranges)
  return items
end

return {
  "stevearc/aerial.nvim",
  event = "LazyFile",
  opts = function()
    local opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      show_guides = true,
      layout = {
        max_width = { 30, 0.2 },
        default_direction = "prefer_left",
        resize_to_content = true,
      },
      ignore = {
        diff_windows = false,
      },
        filter_kind = { "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method", "String", "Struct" },
      post_add_all_symbols = function(bufnr, items, ctx)
        return post_proccess(bufnr, items, ctx)
      end,
    }
    return opts
  end,
  keys = {
    {
      "<leader>ua",
      function()
        vim.cmd("AerialToggle")
        if vim.bo.filetype == "aerial" then
          vim.cmd([[wincmd p]])
        end
      end,
      desc = "Aerial (Symbols)",
    },
  },
}
