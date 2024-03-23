local Config = require("lazyvim.config")

return {
  desc = "Aerial Symbol Browser",
  {
    -- "stevearc/aerial.nvim",
    "linusboehm/aerial.nvim",
    branch = "my_features",
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
