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
        sh = { "shellcheck" },
      },
      linters = {
        markdownlint = {
          args = { "--config", "/home/lboehm/.markdownlint.yaml" },
        },
        shellcheck = {
          args = {
            "--format",
            "json",
            "-e",
            "SC1091,2164,2059",
            "-",
          },
        },
      },
    },
  },
}
