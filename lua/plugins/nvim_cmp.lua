return {
  -- Use <tab> for completion and snippets (supertab)
  -- first: disable default <tab> and <s-tab> behavior in LuaSnip
  {
    "rafamadriz/friendly-snippets",
    enabled = false,
  },
  {
    "L3MON4D3/LuaSnip",
    -- enabled = false,
    keys = function()
      return {}
    end,
    dependencies = {
      {
        "rafamadriz/friendly-snippets",
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
    },
  },

  {
    "hrsh7th/nvim-cmp",
    -- enabled = false,
    dependencies = {
      "rafamadriz/friendly-snippets", -- snippets for a bunch of languages
      "zbirenbaum/copilot.lua", -- snippets for a bunch of languages
      -- these are defaulted:
      -- "hrsh7th/cmp-buffer", "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-path"
    },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local luasnip = require("luasnip")
      local cmp = require("cmp")
      opts.preselect = cmp.PreselectMode.None
      opts.window = {
        documentation = {
          border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
        },
      }
      opts.completion = { completeopt = "menu,menuone,noinsert,noselect" }

      opts.mapping = vim.tbl_extend("force", opts.mapping, {

        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.locally_jumpable(1) then
            luasnip.jump(1)
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<CR>"] = cmp.mapping({
          i = function(fallback)
            if cmp.visible() and cmp.get_active_entry() then
              cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
            else
              fallback()
            end
          end,
          s = cmp.mapping.confirm({ select = true }),
          c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace }),
        }),
      })

      opts.sources = cmp.config.sources({
        -- suggestions are in this order!!!
        { name = "nvim_lsp" },
        { name = "path" },
        { name = "copilot" },
        { name = "luasnip" },
        {
          name = "buffer",
          -- source all buffers (not just current buffer)
          option = {
            get_bufnrs = function()
              local buf = vim.api.nvim_get_current_buf()
              local byte_size = vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf))
              -- limit size of buffers!
              if byte_size > 1024 * 100 then -- 100 Kibyte max
                return {}
              end
              return { buf }
            end,
          },
        },
      })
    end,
  },
}
