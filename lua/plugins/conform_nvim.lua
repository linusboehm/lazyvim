return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ["cmake"] = { "cmake_format" },
        ["cpp"] = { "clang_format" },
        ["markdown"] = { { "prettierd", "prettier" }, "markdownlint" },
        ["markdown.mdx"] = { { "prettierd", "prettier" } },
        ["python"] = { "ruff_fix", "isort", "darker" },
        ["shell"] = { "shfmt", "shellharden" },
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
      },
    },
  },
}
