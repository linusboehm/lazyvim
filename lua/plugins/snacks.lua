local term_utils = require("util.toggletem_utils")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local scratch_run = require("util.scratch_run")

local logo = [[
                    ███████            
                  ██░░░░░░░██          
                ██░░░░░░░░░░░█         
    ██          █░░░░░░░░██░░█████████ 
  ██░░█         █░░░░░░░░░░░░█▒▒▒▒▒▒█  
  █░░░░██       ██░░░░░░░░░░░████████  
 █░░░░░░░█        █░░░░░░░░░█          
█░░░░░░░░░██████████░░░░░░░█           
█░░░░░░░░░░░░░░░░░░░░░░░░░░░██         
█░░░░░░░░░░░░░░░░█░░░░░░░░░░░░█        
██░░░░░░░░█░░░░░░░██░░░░░░░░░░█        
  █░░░░░░░░█████████░░░░░░░███         
   █████░░░░░░░░░░░░░░░████            
        ███████████████                ]]

LAST_CMD = nil

function SearchBashHistory()
  require("telescope.builtin").find_files({
    prompt_title = "Search Bash History",
    cwd = "~",
    find_command = { "bash", "-c", "history -r; tail -n 10000 ~/.bash_history | tac | awk '!/^#/ && !count[$0]++'" },
    previewer = require("telescope.previewers").new_buffer_previewer({
      define_preview = function(self, entry, status)
        -- Set the buffer content to the selected line
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { entry.value })

        local winid = self.state.winid

        vim.wo[winid].wrap = true
        vim.wo[winid].number = false
        vim.wo[winid].relativenumber = false
        vim.wo[winid].signcolumn = "no"

        vim.wo[winid].linebreak = true -- Enable linebreak
        vim.wo[winid].breakindent = true
        vim.wo[winid].breakindentopt = "shift:2" -- Indent by 4 spaces

        vim.bo[self.state.bufnr].filetype = "bash"
      end,
    }),
    sorter = require("telescope.sorters").fuzzy_with_index_bias(),
    layout_strategy = "vertical",
    layout_config = {
      width = 0.75,
      height = 0.5,
      preview_height = 5,
      mirror = true, -- Position preview above results
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local result = selection[1]
        LAST_CMD = result
        term_utils.run_in_terminal(LAST_CMD)
      end)
      return true
    end,
  })
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    bufdelete = { enabled = true },
    scroll = { enabled = false },
    dashboard = {
      enabled = true,
      preset = {
        header = logo,
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 0, padding = 3 },
        -- { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
        { pane = 1, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 3 },
        {
          pane = 1,
          icon = " ",
          title = "Git Status",
          section = "terminal",
          enabled = vim.fn.isdirectory(".git") == 1,
          cmd = "git status --short --branch --renames",
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        { section = "startup" },
        -- { section = "terminal", cmd = "curl -s 'wttr.in/?0'", pane = 1 },
        -- { section = "terminal",
        --   cmd = "$HOME/.config/nvim/lua/plugins/colorstrip",
        --   height = 2,
        --   padding = 1,
        -- },
      },
    },
    git = { enabled = true },
    lazygit = { enabled = true },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    input = {
      win = {
        keys = {
          i_del_word = { "<C-w>", "delete_WORD", mode = "i" },
          i_del_to_slash = { "<A-BS>", "delete_word", mode = "i" },
        },
        actions = {
          delete_WORD = function()
            vim.cmd("normal! diW<cr>")
          end,
          delete_word = function()
            vim.cmd("normal! diw<cr>")
          end,
        },
      },
    },
    scratch = {
      enabled = true,
      ft = function()
        return scratch_run.get_filetype()
      end,
      win = {
        width = scratch_run.opts.win.width,
        height = scratch_run.opts.win.height,
        col = scratch_run.opts.win.boarder,
        bo = { buftype = "", buflisted = false, bufhidden = "hide", swapfile = false },
        minimal = false,
        autowrite = true,
        noautocmd = false,
        -- position = "left",
        zindex = 20,
        wo = { winhighlight = "NormalFloat:Normal" },
        border = "rounded",
        title_pos = "center",
        footer_pos = "center",
      },
      win_by_ft = {
        cpp = {
          keys = {
            ["compile"] = {
              "<cr>",
              function(self)
                local name = "scratch." .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ":e")
                scratch_run.run_cpp({ buf = self.buf, name = name })
              end,
              desc = "Godbolt",
              mode = { "n", "x" },
            },
            ["compile with"] = {
              "<space><cr>",
              function(self)
                local name = "scratch." .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ":e")
                scratch_run.run_cpp({ buf = self.buf, name = name }, "telescope")
              end,
              desc = "Godbolt",
              mode = { "n", "x" },
            },
          },
        },
        python = {
          keys = {
            ["source"] = {
              "<cr>",
              function(self)
                local name = "scratch." .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ":e")
                scratch_run.run_python({ buf = self.buf, name = name })
              end,
              desc = "Source buffer",
              mode = { "n", "x" },
            },
          },
        },
      },
    },
    statuscolumn = { enabled = true },
    terminal = { enabled = true },
    words = { enabled = true },
    zen = {
      toggles = {
        dim = false,
        git_signs = false,
        diagnostics = true,
        inlay_hints = true,
        indent = false,
      },
    },
    indent = {
      enabled = false,
      indent = { hl = "SnacksIndent" },
      scope = { hl = "SnacksIndent", animate = { enabled = false } },
    },
    gitbrowse = {
      enabled = true,
      -- don't just try to open, but also copy to clipboard -> can just paste from remote box
      ---@param url string
      open = function(url)
        Snacks.notify(("git url: [%s]"):format(url), { title = "Git Browse" })
        vim.fn.setreg("+", url)
        if vim.fn.has("nvim-0.10") == 0 then
          require("lazy.util").open(url, { system = true })
          return
        end
        vim.ui.open(url)
      end,
      url_patterns = {
        -- other github addresses
        ["github.e"] = {
          branch = "/tree/{branch}",
          file = "/blob/{branch}/{file}#L{line}",
        },
      },
    },
    styles = { terminal = { keys = { gf = false } } },
  },
  keys = {
    { "<leader>ua", false },
    {
      "<leader>z",
      function()
        Snacks.zen.zoom()
      end,
      desc = "Toggle Zoom",
    },
    {
      "<leader>Z",
      function()
        Snacks.zen()
      end,
      desc = "Toggle Zen Mode",
    },
    {
      "<leader>ts",
      function()
        SearchBashHistory()
      end,
      desc = "search terminal command",
    },
    {
      "<leader>th",
      function()
        Snacks.terminal("LD_LIBRARY_PATH='' htop")
      end,
      desc = "Terminal htop",
    },
    {
      "<leader>tl",
      function()
        if LAST_CMD == nil then
          SearchBashHistory()
        else
          Snacks.notify.info((("executing: [%s]"):format(LAST_CMD)))
          term_utils.run_in_terminal(LAST_CMD)
        end
      end,
      desc = "Terminal python",
    },
    {
      "<leader>tp",
      function()
        scratch_run.scratch_ft("python")
      end,
      desc = "Toggle Scratch Buffer",
    },
    {
      "<leader>tc",
      function()
        scratch_run.scratch_ft("cpp")
      end,
      desc = "Toggle Scratch Buffer",
    },
  },
}
