return {
  {
    url = "https://git.sr.ht/~p00f/godbolt.nvim/",
    cmd = {
      "Godbolt",
      "GodboltCompiler",
    },
    opts = {
      languages = {
        cpp = { compiler = "g131", options = {} },
        -- c = { compiler = "cg122", options = {} },
        -- rust = { compiler = "r1650", options = {} },
      },
      quickfix = {
        enable = true,
        auto_open = true,
      },
    },
    keys = {
      {
        "<leader>cg",
        function()
          vim.cmd("Godbolt")
        end,
        desc = "Godbolt/CompilerExplorer",
      },
      {
        "<leader>cG",
        function()
          vim.cmd("GodboltCompiler telescope")
        end,
        desc = "Godbolt/CompilerExplorer telescope",
      },
    },
  },
}
