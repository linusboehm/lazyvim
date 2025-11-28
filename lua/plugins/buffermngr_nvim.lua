return {
  "git@github.com:linusboehm/buffermngr.nvim",
  dependencies = {
    "akinsho/bufferline.nvim",
    "folke/snacks.nvim",
    "lewis6991/gitsigns.nvim", -- optional
  },
  keys = {
    { "<leader>bm", "<cmd>BufferManager<cr>", desc = "Open Buffer Manager" },
  },
}
