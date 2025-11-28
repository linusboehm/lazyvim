return {
  "git@github.com:linusboehm/scratchbolt.nvim.git",
  dependencies = {
    "folke/snacks.nvim",
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>tc", "<cmd>NvimExplorerCpp<cr>", desc = "Open C++ Explorer" },
    { "<leader>tp", "<cmd>NvimExplorerPython<cr>", desc = "Open Python Explorer" },
  },
}
