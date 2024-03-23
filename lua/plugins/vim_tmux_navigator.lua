return {
  {
    "christoomey/vim-tmux-navigator",
    version = "*",
    keys = {
      { "<C-h>", "<cmd> TmuxNavigateLeft<CR>", mode = { "n" }, desc = "window left" },
      { "<C-l>", "<cmd> TmuxNavigateRight<CR>", mode = { "n" }, desc = "window right" },
      { "<C-j>", "<cmd> TmuxNavigateDown<CR>", mode = { "n" }, desc = "window down" },
      { "<C-k>", "<cmd> TmuxNavigateUp<CR>", mode = { "n" }, desc = "window Up" },
    },
  },
}
