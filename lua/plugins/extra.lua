return {
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = "mason.nvim",
    cmd = { "DapInstall", "DapUninstall" },
    opts = {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      ensure_installed = {
        "cppdbg",
        -- https://github.com/jay-babu/mason-nvim-dap.nvim/blob/main/lua/mason-nvim-dap/mappings/source.lua
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
      { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete other buffers" },
      -- { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete buffers to the right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete buffers to the left" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
    },
  },
  { "nvimtools/none-ls.nvim", enabled = false },
  {
    "windwp/nvim-autopairs",
    event = "VeryLazy",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },
  -- add nightfox
  { "EdenEast/nightfox.nvim" },
  -- -- Configure LazyVim to load gruvbox
  -- { "LazyVim/LazyVim", opts = { colorscheme = "nightfox" } },

  {
    "akinsho/bufferline.nvim",
    keys = {
      { "<leader>bh", "<Cmd>BufferLineMovePrev<CR>", desc = "move current buffer backwards" },
      { "<leader>bl", "<Cmd>BufferLineMoveNext<CR>", desc = "move current buffer forwards" },
      { "<leader>br", false },
    },
  },
  -- { "stevearc/aerial.nvim", false },
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = require("lazyvim.util").root.get() })
        end,
        desc = "Explorer NeoTree (root dir)",
      },
      {
        "<leader>E",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
      -- { "<leader>e", false}, --, "<leader>fe", desc = "Explorer NeoTree (root dir)", remap = true },
      -- { "<leader>E", false}, --, "<leader>fE", desc = "Explorer NeoTree (cwd)", remap = true },
    },
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
    },
  },

  -- makes some plugins dot-repeatable like leap
  { "tpope/vim-repeat", event = "VeryLazy" },
  { "dkarter/bullets.vim", version = "*" },
  { "ThePrimeagen/git-worktree.nvim" },
  { "folke/flash.nvim", opts = { modes = { search = { enabled = false } } } },
  -- { "opdavies/toggle-checkbox.nvim", version = "*" },

  {
    "echasnovski/mini.comment",
    opts = {
      -- Module mappings. Use `''` (empty string) to disable one.
      mappings = {
        -- Toggle comment (like `gcip` - comment inner paragraph) for both
        -- Normal and Visual modes
        comment = "<leader>co",

        -- Toggle comment on current line
        comment_line = "<leader>cc",

        -- Toggle comment on visual selection
        comment_visual = "<leader>cc",

        -- Define 'comment' textobject (like `dgc` - delete whole comment block)
        -- Works also in Visual mode if mapping differs from `comment_visual`
        textobject = "<leader>cc",
      },
    },
  },

  -- session management
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    -- opts = { options = vim.opt.sessionoptions:get() },
    opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals" } },
    -- stylua: ignore
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session for cwd" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
    },
  },
}
