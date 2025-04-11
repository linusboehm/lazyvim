local term_utils = require("util.toggletem_utils")
local home_dir = vim.fn.expand("~")

local logo = [[
                     ███████            
                   ██░░░░░░░██          
                 ██░░░░░░░░░░░█         
     ██         ██░░░░░░░░██░░█████████ 
   ██░░█        ██░░░░░░░░░░░░█▒▒▒▒▒▒█  
   █░░░░██       ██░░░░░░░░░░░████████  
  █░░░░░░░█        █░░░░░░░░░█          
 █░░░░░░░░░██████████░░░░░░░█           
██░░░░░░░░░░░░░░░░░░░░░░░░░░░██         
██░░░░░░░░░░░░░░░░█░░░░░░░░░░░░█        
 ██░░░░░░░░█░░░░░░░██░░░░░░░░░░█        
   █░░░░░░░░█████████░░░░░░░███         
    █████░░░░░░░░░░░░░░░████            
         ███████████████                ]]

LAST_CMD = nil

local idx = 1
local preferred = {
  "default",
  "bottom",
  "dropdown",
}

local set_next_preferred_layout = function(picker)
  idx = idx % #preferred + 1
  picker:set_layout(preferred[idx])
end

local layouts = require("snacks.picker.config.layouts")
local custom_l = vim.deepcopy(layouts.dropdown)
custom_l.layout[1].height = 0.15

local get_file = function()
  local uv = vim.uv or vim.loop
  local branch = ""
  if uv.fs_stat(".git") then
    local ret = vim.fn.systemlist("git branch --show-current")[1]
    if vim.v.shell_error == 0 then
      branch = ret
    end
  end

  local filekey = {
    tostring(vim.v.count1),
    "cmd_hist",
    svim.fs.normalize(assert(uv.cwd())),
    branch,
  }

  local root = vim.fn.stdpath("data") .. "/cmd_hist"
  local fname = Snacks.util.file_encode(table.concat(filekey, "|"))
  local file = root .. "/" .. fname
  file = svim.fs.normalize(file)
  return file
end

local function append_line_to_file(filename, line)
  if line == nil then
    return
  end
  local dir = filename:match("^(.*)/")
  if dir then
    os.execute("mkdir -p " .. dir)
  end
  local file, err = io.open(filename, "a")
  if not file then
    Snacks.notify.info("Could not open file: " .. err)
    return
  end
  file:write(line .. "\n")
  file:close()
  Snacks.notify.info("Appended to file: " .. filename)
  vim.cmd("e " .. vim.fn.fnameescape(filename))
end

function FindCmd(filename)
  Snacks.picker({
    title = "bash history",
    finder = "proc",
    cmd = "bash",
    args = { "-c", "tail -n 10000 ".. filename .. " | tac | awk '!/^#/ && !count[$0]++'" },
    -- name = "cmd",
    format = "text",
    preview = function(ctx)
      if ctx.item.buf and not ctx.item.file and not vim.api.nvim_buf_is_valid(ctx.item.buf) then
        ctx.preview:notify("Buffer no longer exists", "error")
        return
      end
      ctx.preview:set_lines({ ctx.item.text })
      ctx.preview:highlight({ ft = "bash", buf = ctx.buf })
    end,
    layout = custom_l,
    matcher = {
      filename_bonus = false,
      history_bonus = true,
    },
    sort = { fields = { "score:desc", "idx" } },
    win = { preview = { wo = { number = false, relativenumber = false, signcolumn = "no", wrap = true } } },
    confirm = function(picker, item)
      picker:close()
      if item then
        LAST_CMD = item.text
        term_utils.run_in_terminal(LAST_CMD)
      end
    end,
    formatters = { text = { ft = "bash" } },
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

    lazygit = {
      enabled = true,
      interactive = true,
      config = {
        os = { editPreset = "" }, -- use `editPreset = "nvim-remote"` to edit in main nvim window
      },
    },
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
      -- ft = function()
      --   return scratch_run.get_filetype()
      -- end,
      -- win = {
      --   width = scratch_run.opts.win.width,
      --   height = scratch_run.opts.win.height,
      --   col = scratch_run.opts.win.boarder,
      --   bo = { buftype = "", buflisted = false, bufhidden = "hide", swapfile = false },
      --   minimal = false,
      --   autowrite = true,
      --   noautocmd = false,
      --   -- position = "left",
      --   zindex = 20,
      --   wo = { winhighlight = "NormalFloat:Normal" },
      --   border = "rounded",
      --   title_pos = "center",
      --   footer_pos = "center",
      -- },
      -- win_by_ft = {
      --   cpp = {
      --     keys = {
      --       ["compile"] = {
      --         "<cr>",
      --         function(self)
      --           local name = "scratch." .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ":e")
      --           scratch_run.run_cpp({ buf = self.buf, name = name })
      --         end,
      --         desc = "Godbolt",
      --         mode = { "n", "x" },
      --       },
      --       ["compile with"] = {
      --         "<space><cr>",
      --         function(self)
      --           local name = "scratch." .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ":e")
      --           scratch_run.run_cpp({ buf = self.buf, name = name }, "snacks_picker")
      --         end,
      --         desc = "Godbolt",
      --         mode = { "n", "x" },
      --       },
      --     },
      --   },
      --   python = {
      --     keys = {
      --       ["source"] = {
      --         "<cr>",
      --         function(self)
      --           local name = "scratch." .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ":e")
      --           scratch_run.run_python({ buf = self.buf, name = name })
      --         end,
      --         desc = "Source buffer",
      --         mode = { "n", "x" },
      --       },
      --     },
      --   },
      -- },
    },
    statuscolumn = { enabled = true },
    terminal = { enabled = true, interactive = false, win = { wo = { winbar = "" } } },
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
      enabled = true,
      indent = { hl = "SnacksIndent" },
      scope = { hl = "SnacksIndent", animate = { enabled = false } },
    },
    explorer = { enabled = true },
    picker = {
      previewers = { git = { native = true }, diff = { builtin = true, cmd = { "delta" } } },
      formatters = { file = { truncate = 10000 } },
      win = {
        input = {
          keys = {
            ["<c-l>"] = { "focus_preview", mode = { "i", "n" } },
            ["<c-h>"] = { "focus_preview", mode = { "i", "n" } },
            ["<c-v>"] = { "cycle_layouts", mode = { "i", "n" } },
          },
        },
        list = {
          keys = {
            ["<c-l>"] = { "focus_preview", mode = { "i", "n" } },
            ["<c-h>"] = { "focus_preview", mode = { "i", "n" } },
            ["<c-k>"] = { "focus_input", mode = { "i", "n" } },
            ["<c-j>"] = { "focus_input", mode = { "i", "n" } },
          },
        },
        preview = {
          keys = {
            ["<c-l>"] = { "focus_input", mode = { "i", "n" } },
            ["<c-h>"] = { "focus_input", mode = { "i", "n" } },
            ["<c-k>"] = { "focus_list", mode = { "i", "n" } },
            ["<c-j>"] = { "focus_list", mode = { "i", "n" } },
          },
        },
      },
      actions = {
        cycle_layouts = function(picker)
          set_next_preferred_layout(picker)
        end,
      },
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
    styles = {
      terminal = { keys = { gf = false } },
      notification = { wo = { wrap = true } },
    },
  },
  -- stylua: ignore
  keys = {
    { "<leader>ua", false },
    { "<leader>z", function() Snacks.zen.zoom() end, desc = "Toggle Zoom", },
    { "<leader>Z", function() Snacks.zen() end, desc = "Toggle Zen Mode", },
    { "<leader>ts", function() FindCmd("~/.bash_history") end, desc = "search terminal command", },
    { "<leader>td", function() FindCmd(get_file()) end, desc = "search dir hist command", },
    { "<leader>ta", function() append_line_to_file(get_file(), LAST_CMD) end, desc = "Append command to dir history", },
    { "<leader>n", function() Snacks.picker.notifications({ win = { preview = { wo = { wrap = true } } } }) end, desc = "Notification History" },
    { "<leader>th", function() Snacks.terminal("htop") end, desc = "Terminal htop", },
    { "<leader>tl",
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
    -- ---------------------------------
    -- picker keys
    { "<leader>,", false, desc = "Buffers" },
    -- { "<leader>sb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    -- { "<leader>/", function()
    --                   local res = Snacks.picker.get({source = "explorer"})
    --                   if #res > 0
    --                   then
    --                     res[1].input.win:focus()
    --                   else
    --                     Snacks.explorer({focus = "input"})
    --                   end
    --               end,
    --   desc = "Grep (Root Dir)" },
    { "<leader>:", false, desc = "Command History" },
    { "<leader>;", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader><space>", false, desc = "Find Files (Root Dir)" },
    -- disable find
    { "<leader>fb", false, desc = "Buffers" },
    { "<leader>fc", false, desc = "Find Config File" },
    { "<leader>ff", false, desc = "Find Files (Root Dir)" },
    { "<leader>fF", false, desc = "Find Files (cwd)" },
    { "<leader>fg", false, desc = "Find Files (git-files)" },
    { "<leader>fr", false, desc = "Recent" },
    { "<leader>fR", false, desc = "Recent (cwd)" },
    { "<leader>e", function() Snacks.explorer({focus = "input"}) end, desc = "File Explorer" },

    -- find
    { "<leader>sb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>sc", LazyVim.pick.config_files(), desc = "Find Config File" },
    { "<leader>sf", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    -- { "<leader>sF", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" }, -- TODO(lboehm): find under dir of currently open file
    -- { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
    -- { "<leader>br", LazyVim.pick("oldfiles"), desc = "Recent" },
    { "<leader>br", function() Snacks.picker.recent({ filter = { cwd = false }}) end, desc = "Recent" },
    -- { "<leader>br", function() Snacks.picker.recent() end, desc = "Recent" },
    -- { "<leader>fR", LazyVim.pick("oldfiles", { filter = { cwd = true }}), desc = "Recent (cwd)" },
    -- git
    { "<leader>gc", function() Snacks.picker.git_log() end, desc = "Git Log" },
    -- { "<leader>gD", function() Snacks.picker.git_diff() end, desc = "Git Diff (hunks)" }, -- TODO(lboehm): check this
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },

    -- Grep
    -- { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    -- { "<leader>sb", false, desc = "Buffer Lines" },
    { "<leader>sB", false, desc = "Grep Open Buffers" },
    { "<leader>sio", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
    { "<leader>sib", function() local file_p = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.") Snacks.picker.grep({ glob = file_p }) end, desc = "Grep current buffer" },
    { "<leader>sis", function() local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h") Snacks.picker.grep({ dirs = { path } }) end, desc = "Grep subdirs" },
    { "<leader>so", function() Snacks.picker.grep({dirs={home_dir .. "/vaults/work/", home_dir .. "/anki/"}}) end, desc = "Grep obsidian" },
    { "<leader>sl", function() Snacks.picker.grep({dirs={home_dir .. "/.local/share/nvim/lazy/"}}) end, desc = "Search lua/nvim plugins" },


    { "<leader>sg", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
    { "<leader>sG", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },  -- TODO(lboehm): find under dir of currently open file
    { "<leader>sw", LazyVim.pick("grep_word"), desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
    { "<leader>sW", false, desc = "Visual selection or word (cwd)", mode = { "n", "x" } },
    { "<leader>sW", LazyVim.pick("grep_word", { buffers = true }), desc = "Visual selection or word in Buffers", mode = { "n", "x" } },
    -- search
    { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
    { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
    { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
    { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<c-/>", function() Snacks.terminal() end, desc = "Toggle terminal" },
    { "<c-_>", function() Snacks.terminal() end, desc = "Toggle terminal" },
    -- { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
    -- { "<leader>sl", false, desc = "Location List" },
    -- { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
    { "<leader>sM", false, desc = "Man Pages" },
    { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
    { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
    -- { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    { "<leader>sq", function() Snacks.picker.grep({dirs={home_dir .. "/.local/share/db_ui" }}) end, desc = "Search db queries" },
    { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    { "<leader>qp", function() Snacks.picker.projects() end, desc = "Projects" },
  },
}
