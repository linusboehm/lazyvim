local function read_json_file(file_path)
  local lines = vim.fn.readfile(file_path)
  local content = table.concat(lines, "\n")
  return vim.fn.json_decode(content)
end

local function get_db_entries_from_dir(directory)
  local file_list = vim.fn.globpath(directory, "*", false, true)
  local entries = {}
  for _, file_path in ipairs(file_list) do
    local data = read_json_file(file_path)
    if data then
      local entry = {
        name = vim.fn.fnamemodify(file_path, ":t"),
        url = ("postgres://%s:%s@%s:%s/%s"):format(data.user, data.password, data.host, data.port, data.dbname),
      }
      table.insert(entries, entry)
    end
  end
  return entries
end

return {
  "kristijanhusak/vim-dadbod-ui",
  dependencies = {
    { "tpope/vim-dadbod", lazy = true },
    { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
  },
  init = function()
    vim.g.db_ui_auto_execute_table_helpers = 1
    -- vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
    vim.g.db_ui_show_database_icon = true
    -- vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
    vim.g.db_ui_use_nerd_fonts = true
    vim.g.db_ui_use_nvim_notify = true

    -- NOTE: The default behavior of auto-execution of queries on save is disabled
    -- this is useful when you have a big query that you don't want to run every time
    -- you save the file running those queries can crash neovim to run use the
    -- default keymap: <leader>S
    vim.g.db_ui_execute_on_save = false
  end,
  config = function()
    local home_dir = vim.fn.expand("~")
    local directory = home_dir .. "/creds/db"
    vim.g.dbs = get_db_entries_from_dir(directory)
  end,
  keys = { { mode = { "n" }, "<leader>dd", "<cmd>DBUIToggle<cr>", { desc = "DB" } } },
}
