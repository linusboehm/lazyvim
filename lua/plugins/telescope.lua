local Snacks = require("snacks")
local home_dir = vim.fn.expand("~")

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
    -- {
    --   "<leader>,",
    --   "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>",
    --   desc = "Switch Buffer",
    -- },
    { "<leader>/", LazyVim.pick("live_grep", { cwd = Snacks.git.get_root() }), desc = "Grep (root dir)" },
    { "<leader>sl", LazyVim.pick("live_grep", { cwd = vim.fn.stdpath('config') }), desc = "Grep nvim config" },
    { "gc", "<cmd>Telescope lsp_incoming_calls<cr>", desc = "Goto incoming calls" },
    { "<leader>;", "<cmd>Telescope command_history<cr>", desc = "Command History" },
    { "<leader><space>", false }, --, LazyVim.pick.telescope("files"), desc = "Find Files (root dir)" },
    { "<leader>gs", false }, -- "<cmd>Telescope git_status<CR>", desc = "status" },
    { "<leader>sb", false }, -- , "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Buffer" },
    { "<leader>sb", "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Search buffer names" },
    {
      "<leader>so",
      LazyVim.pick("live_grep", {
        prompt_title = "find string in anki/obsidian...",
        search_dirs = {
          home_dir .. '/vaults',
          home_dir .. '/anki',
        }
      }),
      desc = "Search obsidian",
    },
    {
      "<leader>sib",
      LazyVim.pick("live_grep", {
        prompt_title = "find string in open buffers...",
        grep_open_files = true,
      }),
      desc = "Search in buffers",
    },
    { "<leader>sf", LazyVim.pick("auto", { root = Snacks.git.get_root() }), desc = "Find Files (root dir)" },
    { "<leader>sF", LazyVim.pick("auto", { root = false }), desc = "Find Files (cwd)" },
    { "<leader>br", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
    {
      "<leader>sw",
      LazyVim.pick("grep_string", { root = Snacks.git.get_root(), word_match = "-w" }),
      desc = "Word under cursor (root dir)",
    },
    {
      "<leader>sW",
      LazyVim.pick("grep_string", { grep_open_files = true, word_match = "-w" }),
      desc = "Word in buffers",
    },
    -- find
    { "<leader>fb", false }, --, "<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>", desc = "Buffers" },
    { "<leader>fc", false }, --, LazyVim.pick.telescope.config_files(), desc = "Find Config File" },
    { "<leader>ff", false }, --, LazyVim.pick.telescope("files"), desc = "Find Files (root dir)" },
    { "<leader>fF", false }, --, LazyVim.pick.telescope("files", { cwd = false }), desc = "Find Files (cwd)" },
    { "<leader>fg", false }, --, "<cmd>Telescope git_files<cr>", desc = "Find Files (git-files)" },
    { "<leader>fr", false }, --, "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
    { "<leader>fR", false }, --, LazyVim.pick.telescope("oldfiles", { cwd = vim.uv.cwd() }), desc = "Recent (cwd)" },
    -- { "<leader>ss", false },
    -- { "<leader>sS", false },
  },
}
