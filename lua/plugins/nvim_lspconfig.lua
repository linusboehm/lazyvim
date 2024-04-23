return {
  -- add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        pyright = {},
        sqlls = {},
      },
    },
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "<leader>cc", false, mode = { "n", "v" } }
      keys[#keys + 1] =
        { "gh", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch source/header", mode = { "n", "v" } }
      -- { "gh", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch source/header" },
      -- keys[#keys + 1] = { "<leader>cC", false }

      -- If you want insert `(` after select function or method item
      -- parentheses with autocomplete!!!
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
}
