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

        -- Configure clangd to exclude proto files
        clangd = {
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }, -- removed "proto"
        },
        -- Add buf_ls for proto files
        buf_ls = {},
      },
    },
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      keys[#keys + 1] = { "<leader>cc", false, mode = { "n", "v" } }
      keys[#keys + 1] =
        { "gh", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch source/header", mode = { "n", "v" } }
    end,
  },
}
