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
        ["markdown"] = { "prettier", "markdownlint" },
        -- ["sql"] = { "sql_formatter", "sqlfluff" },
        ["sql"] = { "sqlfluff" },
        ["markdown.mdx"] = { "prettier" },
        -- ["python"] = { "ruff_fix", "isort", "darker" },
        ["python"] = {}, -- handled by ruff lsp (lsp_fallback = "always")
        ["proto"] = { "buf" },
        -- ["python"] = { "yapf" },
        ["shell"] = { "shfmt", "shellharden" },
        ["sh"] = { "shfmt", "shellharden" },
        ["gitcommit"] = { "prettier_gitcommit" },
        ["coby"] = { "coby_format" },
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
        sqlfluff = {
          exit_codes = { 0, 1 },
        },
        prettier_gitcommit = {
          command = "format_git.sh",
        },
        coby_format = {
          command = "python3.12",
          args = { vim.fn.expand("~") .. "/.local/coby-tools/coby_format.py", "--check-ids", "--verify" },
          stdin = true,
        },
      },
    },
    keys = {
      {
        mode = { "n" },
        "<Leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = "always" }, function(err, did_edit)
            local Snacks = require("snacks")
            if err and err:match("No result returned from LSP formatter") then
              Snacks.notify.info("No formatting changes", { title = "formatting" })
            elseif err then
              Snacks.notify.error("Error formatting: " .. err, { title = "formatting" })
            end
          end)
        end,
        desc = "Format",
      },
      {
        mode = { "v" },
        "<Leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = "always" }, function(err, did_edit)
            local Snacks = require("snacks")
            if err and err:match("No result returned from LSP formatter") then
              Snacks.notify.info("No formatting changes", { title = "formatting" })
            elseif err then
              Snacks.notify.error("Error formatting: " .. err, { title = "formatting" })
            end
            vim.defer_fn(function()
              vim.api.nvim_input("<esc>")
            end, 1)
          end)
        end,
        desc = "Format",
      },
      {
        "<leader>ch",
        function()
          local ignore_filetypes = { "lua" }
          if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
            vim.notify("range formatting for " .. vim.bo.filetype .. " not working properly.")
            return
          end

          local hunks = require("gitsigns").get_hunks()
          if hunks == nil then
            return
          end

          local format = require("conform").format

          local function format_range()
            if next(hunks) == nil then
              vim.notify("done formatting git hunks", "info", { title = "formatting" })
              return
            end
            local hunk = nil
            while next(hunks) ~= nil and (hunk == nil or hunk.type == "delete") do
              hunk = table.remove(hunks)
            end

            if hunk ~= nil and hunk.type ~= "delete" then
              local start = hunk.added.start
              local last = start + hunk.added.count
              -- nvim_buf_get_lines uses zero-based indexing -> subtract from last
              local last_hunk_line = vim.api.nvim_buf_get_lines(0, last - 2, last - 1, true)[1]
              local range = { start = { start, 0 }, ["end"] = { last - 1, last_hunk_line:len() } }
              format({ range = range, async = true, lsp_fallback = true }, function()
                vim.defer_fn(function()
                  format_range()
                end, 1)
              end)
            end
          end

          format_range()
        end,
        desc = "format git hunks",
      },
    },
  },
}
