local term_utils = require("util.toggletem_utils")
local scratch_run = require("util.scratch_run")

local fzf_lua = require("fzf-lua")

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
  local opts = vim.tbl_extend("force", {
    prompt = "history" .. "> ",
    preview = {
      type = "cmd",
      fn = function(items)
        return string.format("echo %s | bat --style=plain --color=always -l bash --theme='tokyonight_night'", items[1])
      end,
    },
    fzf_opts = {
      ["--scheme"] = "history",
    },
    winopts = {
      preview = {
        wrap = "wrap",
        vertical = "up:3",
        layout = "vertical",
      },
    },
    fn_transform = function(x)
      return fzf_lua.utils.ansi_codes.magenta(x)
    end,
    actions = {
      ["default"] = function(selected)
        if not selected or vim.tbl_isempty(selected) then
          return
        end
        LAST_CMD = selected[1]
        term_utils.run_in_terminal(LAST_CMD)
      end,
    },
  }, opts or {})
  fzf_lua.fzf_exec("history -r; tail -n 10000 ~/.bash_history | tac | awk '!/^#/ && !count[$0]++'", opts)
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
                scratch_run.run_cpp({ buf = self.buf, name = name }, "fzflua")
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
