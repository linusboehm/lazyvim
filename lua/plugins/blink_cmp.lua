return {
  {
    "saghen/blink.cmp",
    event = "VeryLazy",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      completion = {
        list = {
          max_items = 50,
          selection = { preselect = false, auto_insert = false },
        },
        accept = { auto_brackets = { enabled = true } },
        menu = {
          draw = {
            treesitter = { "lsp" },
          },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      sources = {
        providers = {
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink", score_offset = 3 },
        },
        -- per_filetype = {
        --   codecompanion = { "codecompanion" },
        -- },
      },
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
    },
  },
}
