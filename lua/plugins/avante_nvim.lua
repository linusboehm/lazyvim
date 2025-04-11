return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  opts = {
    file_selector = "snacks",
    provider = "copilot",
    copilot = {
      model = "claude-3.7-sonnet",
      -- timeout = 30000, -- increase for reasoning models
      -- temperature = 0,
      max_tokens = 8192,
    },
  },
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "zbirenbaum/copilot.lua",
  },
}
