return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      servers = {
        -- Use pyrefly instead of pyright/basedpyright
        pyright = { enabled = false },
        pyrefly = {},
        sqlls = {
          settings = {
            sqlLanguageServer = {
              lint = {
                rules = {
                  ["align-column-to-clause"] = "off",
                  ["align-where"] = "off",
                  ["column-require"] = "off",
                },
              },
            },
          },
        },

        -- Configure clangd to exclude proto files
        clangd = {
          enables = false,
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" }, -- removed "proto"
          keys = {
            { "gh", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Switch source/header" },
          },
        },

        ruff = {
          keys = {
            {
              "<leader>co",
              function()
                vim.lsp.buf.code_action({
                  apply = true,
                  context = {
                    only = { "source.organizeImports" },
                    diagnostics = {},
                  },
                })
              end,
              desc = "Organize Imports",
            },
          },
          init_options = {
            settings = {
              lint = {
                select = { "E", "W", "F", "C", "S", "PL" },
                ignore = { "PLR0913", "PLW1508" },
              },
            },
          },
        },

        -- Global keymaps for all LSP servers
        ["*"] = {
          keys = {
            { "<leader>cc", false, mode = { "n", "v" } }, -- disable default keymap
          },
        },
      },
    },
  },
}
