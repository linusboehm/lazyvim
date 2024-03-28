return {
  {
    "echasnovski/mini.indentscope",
    enabled = true,
    -- disable = function(_, buf)
    --   -- disable for large files as it get super slow
    --   local max_filesize = 100 * 1024 -- 100 KB
    --   local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
    --   if ok and stats and stats.size > max_filesize then
    --     return true
    --   end
    -- end,
    opts = {
      draw = {
        animation = require("mini.indentscope").gen_animation.none(),
      },
    },
  },
}
