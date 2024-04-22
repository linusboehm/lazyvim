local prettier = { "prettier", "prettierd" }
return {
  {
    "stevearc/conform.nvim",
    dependencies = {
      { "lewis6991/gitsigns.nvim", lazy = true },
    },
    opts = {
      formatters_by_ft = {
        ["cmake"] = { "cmake_format" },
        ["cpp"] = { "clang_format" },
        ["markdown"] = { prettier, "markdownlint" },
        ["markdown.mdx"] = { prettier },
        -- ["python"] = { "ruff_fix", "isort", "darker" },
        ["python"] = {},
        -- ["python"] = { "yapf" },
        ["shell"] = { "shfmt", "shellharden" },
        ["sh"] = { "shfmt", "shellharden" },
        ["gitcommit"] = { "prettier_gitcommit" },
        ["_"] = { "trim_whitespace" },
      },
      formatters = {
        shfmt = {
          prepend_args = { "-i", "2", "-ci" },
        },
        prettier = {
          prepend_args = { "--print-width", "100", "--prose-wrap", "always" },
        },
        prettierd = {
          prepend_args = { "--print-width", "100", "--prose-wrap", "always" },
        },
        prettier_gitcommit = {
          command = "format_git.sh",
        },
      },
    },
    keys = {
      {
        "<leader>ch",
        function()
          local ignore_filetypes = { "lua" }
          if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
            vim.notify("range formatting for " .. vim.bo.filetype .. " not working properly.")
            return
          end
          local hunks = require("gitsigns").get_hunks()
          local format = require("conform").format
          for _, hunk in pairs(hunks) do
            if hunk ~= nil then
              local start = hunk.added.start
              local last = start + hunk.added.count
              -- nvim_buf_get_lines uses zero-based indexing -> subtract from last
              local last_hunk_line = vim.api.nvim_buf_get_lines(0, last - 2, last - 1, true)[1]
              local range = { start = { start, 0 }, ["end"] = { last - 1, last_hunk_line:len() } }
              format({ range = range })
            end
          end
        end,
        desc = "format git hunks",
      },
    },
  },
}
