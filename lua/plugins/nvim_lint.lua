return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        cmake = { "cmakelint" },
        cpp = { "cpplint" },
        dockerfile = { "hadolint" },
        lua = { "selene" },
        markdown = { "markdownlint" },
        proto = { "protolint" },
      },
      linters = {
        markdownlint = {
          args = { "--config", "/home/lboehm/.markdownlint.yaml" },
        },
      },
    },
  },
}
