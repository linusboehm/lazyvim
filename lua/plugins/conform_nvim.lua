return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        ["cmake"] = { "cmake_format" },
        ["cpp"] = { "clang_format" },
        ["markdown"] = { { "prettierd", "prettier" }, "markdownlint" },
        ["markdown.mdx"] = { { "prettierd", "prettier" } },
        ["python"] = { "ruff_fix", "isort", "darker" },
        ["shell"] = { "shfmt", "shellharden" },
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
          command = "format_git.sh"
        },
      },
    },
  },
}
