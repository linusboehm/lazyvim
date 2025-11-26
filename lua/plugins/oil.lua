return {
  "stevearc/oil.nvim",
  opts = {
    float = {
      -- max_width and max_height can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
      max_width = 0.8,
      max_height = 60,
      border = "rounded",
    },
    view_options = {
      -- Show files and directories that start with "."
      show_hidden = true,
    },
  },
  keys = {
    {
      "-",
      function()
        require("oil").toggle_float()
      end,
      desc = "Open parent directory",
      mode = "n",
    },
  },
}
