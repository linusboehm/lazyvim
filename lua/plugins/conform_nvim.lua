return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ["markdown"] = { { "prettierd", "prettier" }, "markdownlint" },
        ["markdown.mdx"] = { { "prettierd", "prettier" } },
        ["cmake"] = { "cmake_format" },
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
