local Util = require("lazyvim.util")
local Misc = require("util.misc")

return {
  "nvim-telescope/telescope.nvim",
  -- change some options
  opts = {
    defaults = {
      layout_strategy = "horizontal",
      -- sorting_strategy = "ascending",
      winblend = 0,
    },
  },
  keys = {
    -- original: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/editor.lua
    {
      "<leader>,",
      "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
      desc = "Switch Buffer",
    },
    -- { "<leader>/", LazyVim.telescope("live_grep"), desc = "Grep (root dir)" },
    { "gc", "<cmd>Telescope lsp_incoming_calls<cr>", desc = "Goto incoming calls" },
    { "<leader>;", "<cmd>Telescope command_history<cr>", desc = "Command History" },
    { "<leader><space>", false }, --, LazyVim.telescope("files"), desc = "Find Files (root dir)" },
    { "<leader>gs", false }, -- "<cmd>Telescope git_status<CR>", desc = "status" },
    { "<leader>sb", false }, -- , "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer" },
    { "<leader>sb", "<cmd>Telescope buffers<cr>", desc = "Search buffer names" },
    {
      "<leader>sib",
      Util.telescope("live_grep", {
        prompt_title = "find string in open buffers...",
        grep_open_files = true,
      }),
      desc = "Search in buffers",
    },
    { "<leader>sf", Util.telescope("files", { cwd = Misc.get_git_root() }), desc = "Find Files (root dir)" },
    { "<leader>sF", Util.telescope("files", { cwd = false }), desc = "Find Files (cwd)" },
    { "<leader>br", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
    {
      "<leader>sw",
      Util.telescope("grep_string", { cwd = Misc.get_git_root() }),
      desc = "Word under cursor (root dir)",
    },
    { "<leader>sW", Util.telescope("grep_string", { grep_open_files = true }), desc = "Word in buffers" },
    -- find
    { "<leader>fb", false }, --, "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Buffers" },
    { "<leader>fc", false }, --, LazyVim.telescope.config_files(), desc = "Find Config File" },
    { "<leader>ff", false }, --, LazyVim.telescope("files"), desc = "Find Files (root dir)" },
    { "<leader>fF", false }, --, LazyVim.telescope("files", { cwd = false }), desc = "Find Files (cwd)" },
    { "<leader>fg", false }, --, "<cmd>Telescope git_files<cr>", desc = "Find Files (git-files)" },
    { "<leader>fr", false }, --, "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
    { "<leader>fR", false }, --, LazyVim.telescope("oldfiles", { cwd = vim.uv.cwd() }), desc = "Recent (cwd)" },
    -- { "<leader>ss", false },
    -- { "<leader>sS", false },
  },
}
