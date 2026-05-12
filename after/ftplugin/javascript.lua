if vim.b.dbui_db_key_name ~= nil and vim.b.dbui_db_key_name ~= "" then
  require("util.dadbod").map_execute_current_paragraph()
end
