return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      servers = {
        -- Use pyrefly instead of pyright/basedpyright
        pyright = { enabled = false },
        pyrefly = {
          handlers = {
            ["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
              -- Prefix all pyrefly diagnostics with "Pyrefly:"
              if result and result.diagnostics then
                for _, diagnostic in ipairs(result.diagnostics) do
                  if diagnostic.message and not diagnostic.message:match("Pyrefly:") then
                    diagnostic.message = "Pyrefly: " .. diagnostic.message
                  end
                end
              end
              vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
            end,
          },
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                inlayHints = {
                  functionReturnTypes = true,
                  variableTypes = true,
                  parameterTypes = true,
                },
              },
            },
          },
        },
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
            { "<leader>cc", false, mode = { "n", "x" }, has = "codeLens" },
          },
        },
      },
    },
  },
}
