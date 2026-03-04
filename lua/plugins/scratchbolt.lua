return {
  "git@github.com:linusboehm/scratchbolt.nvim.git",
  -- dir = "/local/home/lboehm/repos/scratchbolt.nvim",
  -- name = "scratchbolt.nvim",
  dependencies = {
    "folke/snacks.nvim",
    "nvim-lua/plenary.nvim",
  },
  keys = {
    { "<leader>tc", "<cmd>NvimExplorerCpp<cr>", desc = "Open C++ Explorer" },
    { "<leader>tp", "<cmd>NvimExplorerPython<cr>", desc = "Open Python Explorer" },
  },
}
