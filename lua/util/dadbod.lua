local M = {}

function M.map_execute_current_paragraph()
  vim.keymap.set("n", "<leader>S", "vip<Plug>(DBUI_ExecuteQuery)", {
    buffer = true,
    desc = "execute SQL paragraph",
    nowait = true,
    remap = true,
    silent = true,
  })
end

return M
