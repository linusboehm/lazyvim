return {
  "kristijanhusak/vim-dadbod-ui",
  dependencies = {
    { "tpope/vim-dadbod", lazy = true },
    { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
  },
  cmd = {
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
  },
  config = function()
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_execute_on_save = 0
    vim.g.dbs = {
      -- {
      --   name = "some_name",
      --   url = "postgres://user:" .. get_password() .. "@host:port/dbname",
      -- },
    }
  end,
  keys = { { mode = { "n" }, "<leader>dd", "<cmd>DBUIToggle<cr>", { desc = "DB" } } },
}
