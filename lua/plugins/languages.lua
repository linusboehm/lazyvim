return {
  {
    "nvim-treesitter/nvim-treesitter",
    enable = true,
    opts = function(_, opts)
      -- Register coby parser configuration

      -- Add your languages plus coby to LazyVim's defaults
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "cpp",
        "json",
        "lua",
        "python",
        "query",
        "regex",
        "sql",
        "vim",
        "vimdoc",
        "yaml",
        -- "markdown",
        -- "markdown_inline",
      })

      -- vim.list_extend(opts.highlight = {
      --   enable = true,
      --
      --   disable = function(lang, buf)
      --     -- local ignore_types = { "c", "rust", "cpp" }
      --     -- if misc_util.IsInList(lang, ignore_types) then
      --     --   return true
      --     -- end
      --     local max_filesize = 100 * 1024 -- 100 KB
      --     local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      --     if ok and stats and stats.size > max_filesize then
      --       return true
      --     end
      --   end,
      --
      --   additional_vim_regex_highlighting = false,
      -- }),

      return opts
    end,
  },

  -- add any tools you want to have installed below
  {
    "mason-org/mason.nvim",
    -- enabled = false,
    event = "VeryLazy",
    -- Completely replace whatever LazyVim / others configured
    -- this is only needed to get rid of stylua (which doesn't work on EL8)
    opts = function(_, opts)
      opts.ensure_installed = { -- "black",
        "clang-format",
        "clangd",
        "pyrefly",
        "cmakelang",
        "cmakelint", -- for cmake_lint
        "cpplint",
        "markdownlint",
        "prettier",
        "prettierd",
        "protolint",
        "ruff",
        "rust-analyzer",
        "shellharden",
        "shfmt",
        "shellcheck",
        -- "stylua", -> install with `cargo install stylua --locked`, because of glibc error on centos8
      }
    end,
    -- -- merge with upstream config
    -- opts = {
    --   ensure_installed = {
    --     "clang-format",
    --     "clangd",
    --     ...
    --   },
    -- },
  },
}
