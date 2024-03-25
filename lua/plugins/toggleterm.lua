-- map("n", "<Leader>tl", run_last, { desc = "run last" })

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    event = "VeryLazy",
    keys = {
      {
        mode = { "n" },
        "<Leader>th",
        require("util.toggletem_utils").htop_toggle,
        desc = "toggle htop",
      },
      {
        mode = { "n" },
        "<Leader>tp",
        require("util.toggletem_utils").python_toggle,
        desc = "toggle python",
      },
      {
        mode = { "n" },
        "<Leader>tl",
        require("util.toggletem_utils").run_last,
        desc = "run last",
      },
    },
    opts = {
      -- size = 20,
      open_mapping = [[<C-t>]],
      hide_numbers = true,
      auto_scroll = false,
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "horizontal",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "curved",
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
    },
  },
}
