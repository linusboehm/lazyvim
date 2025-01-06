local home_dir = vim.fn.expand("~")

local function get_open_buffers()
  local lazy = require("bufferline.lazy")
  local state = lazy.require("bufferline.state") ---@module "bufferline.state"
  local elements = state.components
  local paths = {}
  for _, name in ipairs(elements) do
    table.insert(paths, name.path)
  end
  return paths
end

return {
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    keys = {
      { "gc", "<cmd>FzfLua lsp_incoming_calls<cr>", desc = "Goto fzf incoming calls" },

      {
        "<leader>,",
        false,
        "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>",
        desc = "Switch Buffer",
      },
      { "<leader>;", "<cmd>FzfLua command_history<cr>", desc = "Command History" },
      { "<leader><space>", false, LazyVim.pick("files"), desc = "Find Files (Root Dir)" },

      -- disable find
      { "<leader>fb", false, "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>", desc = "Buffers" },
      { "<leader>fc", false, LazyVim.pick.config_files(), desc = "Find Config File" },
      { "<leader>ff", false, LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
      { "<leader>fF", false, LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
      { "<leader>fg", false, "<cmd>FzfLua git_files<cr>", desc = "Find Files (git-files)" },
      { "<leader>fr", false, "<cmd>FzfLua oldfiles<cr>", desc = "Recent" },
      { "<leader>fR", false, LazyVim.pick("oldfiles", { cwd = vim.uv.cwd() }), desc = "Recent (cwd)" },

      -- search
      { '<leader>s"', false, "<cmd>FzfLua registers<cr>", desc = "Registers" },
      { "<leader>sa", false, "<cmd>FzfLua autocmds<cr>", desc = "Auto Commands" },
      -- { "<leader>sb", "<cmd>FzfLua grep_curbuf<cr>", desc = "Buffer" },
      { "<leader>sb", "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>", desc = "Search buffer names" },
      { "<leader>sg", false, LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
      { "<leader>sG", false, LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
      { "<leader>sH", false, "<cmd>FzfLua highlights<cr>", desc = "Search Highlight Groups" },
      { "<leader>sj", false, "<cmd>FzfLua jumps<cr>", desc = "Jumplist" },
      -- { "<leader>sl", "<cmd>FzfLua loclist<cr>", desc = "Location List" },
      { "<leader>sl", LazyVim.pick("live_grep", { cwd = vim.fn.stdpath("config") }), desc = "Grep nvim config" },
      { "<leader>sf", LazyVim.pick("files", { cwd = Snacks.git.get_root() }), desc = "Find Files (Root Dir)" },
      { "<leader>sF", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
      { "<leader>br", "<cmd>FzfLua oldfiles<cr>", desc = "Recent" },
      -- { "<leader>so", false },
      -- { "<leader>sl", false, LazyVim.pick.config_files(), desc = "Find nvim config file" },
      {
        "<leader>so",
        LazyVim.pick("live_grep", {
          search_paths = { home_dir .. "/vaults", home_dir .. "/anki" },
        }),
        desc = "Search obsidian",
      },
      {
        "<leader>sq",
        LazyVim.pick("live_grep", {
          cwd = home_dir .. "/.local/share/db_ui",
        }),
        desc = "Search db queries",
      },
      { "<leader>sM", "<cmd>FzfLua man_pages<cr>", desc = "Man Pages" },
      { "<leader>sm", false, "<cmd>FzfLua marks<cr>", desc = "Jump to Mark" },
      { "<leader>sw", LazyVim.pick("grep_cword", { cwd = Snacks.git.get_root() }), desc = "Word (Root Dir)" },

      {
        "<leader>sW",
        function()
          require("fzf-lua").grep_cword({ search_paths = get_open_buffers() })
        end,
        desc = "Word in buffer",
      },
      {
        "<leader>sW",
        function()
          require("fzf-lua").grep_visual({ search_paths = get_open_buffers() })
        end,
        mode = "v",
        desc = "Selection in open biffers",
      },
      {
        "<leader>sib",
        function()
          require("fzf-lua").live_grep({ search_paths = get_open_buffers() })
        end,
        desc = "Search in buffers",
      },
    },
  },
}
