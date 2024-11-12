local term_utils = require("util.toggletem_utils")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

LAST_CMD = nil

function SearchBashHistory()
  Snacks.notify.info("running search!")
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
    gitbrowse = {
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
        Snacks.terminal("htop")
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
