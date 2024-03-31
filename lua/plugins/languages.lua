return {
  -- change treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "json",
        "cpp",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "vim",
        "yaml",
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
        "darker",
        "flake8",
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
