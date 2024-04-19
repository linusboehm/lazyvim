local misc_util = require("util.misc")

return {
  -- change treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    enable = false,
    opts = {
      ensure_installed = {
        "bash",
        "cpp",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "vim",
        "yaml",
      },
      highlight = {
        enable = true,

        disable = function(lang, buf)
          -- local ignore_types = { "c", "rust", "cpp" }
          -- if misc_util.IsInList(lang, ignore_types) then
          --   return true
          -- end
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,

        additional_vim_regex_highlighting = false,
      },
    },
  },

  -- add jsonls and schemastore packages, and setup treesitter for json, json5 and jsonc
  { import = "lazyvim.plugins.extras.lang.json" },
  -- { import = "lazyvim.plugins.extras.editor.aerial" },
  { import = "lazyvim.plugins.extras.formatting.black" },
  { import = "lazyvim.plugins.extras.formatting.prettier" },
  { import = "lazyvim.plugins.extras.lang.clangd" },
  { import = "lazyvim.plugins.extras.editor.harpoon2" },
  { import = "lazyvim.plugins.extras.lang.cmake" },
  { import = "lazyvim.plugins.extras.lang.json" },
  { import = "lazyvim.plugins.extras.lang.markdown" },
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.yaml" },
  { import = "lazyvim.plugins.extras.dap.core" },
  { import = "lazyvim.plugins.extras.coding.copilot" },

  -- add any tools you want to have installed below
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        -- "black",
        "clang-format",
        "clangd",
        "cmakelang",
        "cmakelint", -- for cmake_lint
        "cpplint",
        "codelldb",
        -- "cpptools",
        -- "darker",
        -- "flake8",
        "marksman",
        "markdownlint",
        "prettier",
        "prettierd",
        "protolint",
        "pyright",
        "ruff-lsp",
        "rust-analyzer",
        "selene",
        "shellharden",
        "shfmt",
        "shellcheck",
        "stylua",
      },
    },
  },
}
