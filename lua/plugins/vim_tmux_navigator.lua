vim.g.tmux_navigator_no_mappings = 1

return {
  {
    "christoomey/vim-tmux-navigator",
    version = "*",
    keys = {
      { "<C-h>", "<cmd> TmuxNavigateLeft<CR>", mode = { "n" }, desc = "window left" },
      { "<C-l>", "<cmd> TmuxNavigateRight<CR>", mode = { "n" }, desc = "window right" },
      { "<C-j>", "<cmd> TmuxNavigateDown<CR>", mode = { "n" }, desc = "window down" },
      -- { "<C-k>", "<cmd> TmuxNavigateUp<CR>", mode = { "n" }, desc = "window Up" },
      {
        "<C-k>",
        function()
          vim.api.nvim_command([[TmuxNavigateUp]])
          require("util.misc").go_to_text_buffer()
        end,
        mode = { "n" },
        desc = "window Up",
      },
    },
  },
}
