return {
  {
    url = "https://github.com/linusboehm/godbolt.nvim",
    cmd = {
      "Godbolt",
      "GodboltCompiler",
    },
    opts = {
      languages = {
        cpp = { compiler = "g131", options = { userArguments = "-fsanitize=address -std=c++20 -O0"} },
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
        mode = { "n" },
      },
      {
        "<leader>cG",
        function()
          vim.cmd("GodboltCompiler snacks_picker")
        end,
        desc = "Godbolt/CompilerExplorer pick compiler",
        mode = { "n" },
      },
      {
        "<leader>cg",
        function()
          -- Get the start and end of the visual selection
          local start_line = vim.fn.line("'<")
          local end_line = vim.fn.line("'>")

          -- Run the Godbolt command on the selected lines
          vim.api.nvim_command(start_line .. "," .. end_line .. "Godbolt")
          -- vim.cmd("Godbolt")
        end,
        desc = "Godbolt/CompilerExplorer",
        mode = { "v" },
      },
      {
        "<leader>cG",
        function()
          vim.cmd("'<,'>GodboltCompiler snacks_picker")
        end,
        desc = "Godbolt/CompilerExplorer pick compiler",
        mode = { "v" },
      },
    },
  },
}
