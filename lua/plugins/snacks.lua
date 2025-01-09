local term_utils = require("util.toggletem_utils")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

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

local defaults = {
  name = "Output",
  ft = vim.bo.filetype,
  ---@type string|string[]?
  icon = nil, -- `icon|{icon, icon_hl}`. defaults to the filetype icon
  win = { style = "output" },
}

local height = 20
Snacks.config.style("output", {
  width = 0,
  height = height,
  backdrop = false,
  row = vim.api.nvim_get_option_value("lines", {}) - height,
  bo = { buftype = "nofile", buflisted = false, bufhidden = "wipe", swapfile = false, undofile = false },
  minimal = false,
  noautocmd = false,
  zindex = 100,
  ft = "output",
  wo = { winhighlight = "NormalFloat:Normal", colorcolumn = "" },
})

--- Show lines in a floating buffer at the bottom.
---@param lines string
---@param opts? snacks.scratch.Config
local function show_output(lines, opts)
  opts = Snacks.config.get("output", defaults, opts)
  opts.win = Snacks.win.resolve("output", opts.win, { show = false })

  local out_buf = vim.api.nvim_create_buf(false, true)

  local content = {}
  for line in lines:gmatch("([^\n]*)\n?") do
    table.insert(content, line)
  end
  -- Remove trailing empty lines
  for i = #content, 1, -1 do
    if content[i] == "" then
      table.remove(content, i)
    else
      break
    end
  end
  vim.api.nvim_buf_set_lines(out_buf, 0, -1, false, content)
  opts.win.buf = out_buf
  return Snacks.win(opts.win):show()
end

--- Run the current buffer or a range of lines.
--- Shows the output of `print` inlined with the code.
--- Any error will be shown as a diagnostic.
---@param opts? {name?:string, buf?:number, print?:boolean}
local function runPython(opts)
  local ns = vim.api.nvim_create_namespace("snacks_debug")
  opts = vim.tbl_extend("force", { print = true }, opts or {})
  local buf = opts.buf or 0
  buf = buf == 0 and vim.api.nvim_get_current_buf() or buf
  local name = opts.name or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")

  -- Get the lines to run
  local lines ---@type string[]
  local mode = vim.fn.mode()
  if mode:find("[vV]") then
    if mode == "v" then
      vim.cmd("normal! v")
    elseif mode == "V" then
      vim.cmd("normal! V")
    end
    local from = vim.api.nvim_buf_get_mark(buf, "<")
    local to = vim.api.nvim_buf_get_mark(buf, ">")

    -- for some reason, sometimes the column is off by one
    -- see: https://github.com/folke/snacks.nvim/issues/190
    local col_to = math.min(to[2] + 1, #vim.api.nvim_buf_get_lines(buf, to[1] - 1, to[1], false)[1])

    lines = vim.api.nvim_buf_get_text(buf, from[1] - 1, from[2], to[1] - 1, col_to, {})
    -- Insert empty lines to keep the line numbers
    for _ = 1, from[1] - 1 do
      table.insert(lines, 1, "")
    end
    vim.fn.feedkeys("gv", "nx")
  else
    lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  end

  -- Clear diagnostics and extmarks
  local function reset()
    vim.diagnostic.reset(ns, buf)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  end
  reset()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = vim.api.nvim_create_augroup("snacks_debug_run_" .. buf, { clear = true }),
    buffer = buf,
    callback = reset,
  })

  local command = "echo " .. vim.fn.shellescape(table.concat(lines, "\n")) .. " | python3 2>&1"
  local handle = io.popen(command)
  if not handle then
    Snacks.notify.error("Didn't get popen handle.", { title = name })
    return
  end
  local out = handle:read("*a")
  handle:close()

  if out == "" then
    Snacks.notify.info("No output.", { title = name, ft = "python" })
  else
    show_output(out)
  end
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
      win_by_ft = {
        cpp = {
          keys = {
            ["Godbolt"] = {
              "<leader><cr>",
              function(self)
                vim.cmd("Godbolt")
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
                runPython({ buf = self.buf, name = name })
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
      "<leader>tc",
      function()
        SearchBashHistory()
      end,
      desc = "pick terminal command",
    },
    {
      "<leader>th",
      function()
        Snacks.terminal("LD_LIBRARY_PATH='' htop")
      end,
      desc = "Terminal htop",
    },
    {
      "<leader>tp",
      function()
        Snacks.terminal("python3")
      end,
      desc = "Terminal python",
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
  },
}
