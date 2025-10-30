local configs = require("lspconfig.configs")
local util = require("lspconfig.util")

-- 1) Register Pyrefly as a custom LSP if it doesn’t exist yet
if not configs.pyrefly then
  configs.pyrefly = {
    default_config = {
      cmd = { "pyrefly", "lsp" },
      filetypes = { "python" },
      root_dir = function(fname)
        return util.root_pattern("pyrefly.toml", "pyproject.toml", ".git")(fname) or vim.fs.dirname(fname)
      end,
      settings = {},
    },
  }
end

return {
  -- add pyright to lspconfig
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        pyright = { enabled = false },
        pyrefly = {},
        sqlls = {},

        -- Configure clangd to exclude proto files
        clangd = {
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }, -- removed "proto"
        },
        -- Add buf_ls for proto files
        buf_ls = {},
        ruff = {
          keys = {
            {
              "<leader>co",
              LazyVim.lsp.action["source.organizeImports"],
              desc = "Organize Imports",
            },
          },
          init_options = {
            settings = {
              lint = {
                select = { "E", "W", "F", "C", "S", "PL" },
                -- ignore = { "F", "E7" },
              },
            },
          },
        },
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
