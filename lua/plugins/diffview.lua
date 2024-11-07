return {
  "sindrets/diffview.nvim",
  cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  -- dependencies = {
  --   "nvim-lua/plenary.nvim",
  --   { "NeogitOrg/neogit", opts = { disable_commit_confirmation = true } },
  -- },
  keys = {
    { "<leader>gd", "<cmd>DiffviewFileHistory %<CR>", desc = "Diff File" },
    { "<leader>gv", "<cmd>DiffviewOpen<CR>", desc = "Diff View" },
  },
  opts = {
    enhanced_diff_hl = true, -- See ':h diffview-config-enhanced_diff_hl'
    keymaps = {
      view = {
        ["<C-g>"] = "<CMD>DiffviewClose<CR>",
        ["<leader>gm"] = "<CMD>DiffviewClose<CR>",
        ["c"] = "<CMD>DiffviewClose|Neogit commit<CR>",
      },
      file_panel = {
        ["<C-g>"] = "<CMD>DiffviewClose<CR>",
        ["<leader>gm"] = "<CMD>DiffviewClose<CR>",
        ["c"] = "<CMD>DiffviewClose|Neogit commit<CR>",
      },
    },
    default_args = {
      DiffviewOpen = { "--imply-local" },
      -- DiffviewFileHistory = { "--base=LOCAL" },
    },
    hooks = {
      view_opened = function(view)
        -- print(vim.inspect(view)) -- Print the view object for debugging
        if view.panel.bufname == "DiffviewFilePanel" then  -- DiffViewOpen
          vim.cmd("wincmd l")
          vim.cmd("wincmd x")
          vim.cmd("wincmd h")
        end
        -- if view.panel.bufname == "DiffviewFHOptionPanel" then  -- DiffviewFileHistory
        --   vim.cmd("wincmd l")
        --   vim.cmd("wincmd x")
        --   vim.cmd("wincmd h")
        -- end
      end,
    },
  },
}
