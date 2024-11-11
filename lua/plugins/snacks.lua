local term_utils = require("util.toggletem_utils")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

LAST_CMD = nil

function SearchBashHistory()
  Snacks.notify.info("running search!")
  require("telescope.builtin").find_files({
    prompt_title = "Search Bash History",
    cwd = "~",
    find_command = { "bash", "-c", "awk '!/^#/ && !count[$0]++' ~/.bash_history | tail -n 20 | tac" },
    -- sorting_strategy = "ascending",
    previewer = false,
    layout_config = {
      width = 0.75,
      height = 0.5,
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local result = selection[1]
        Snacks.notify.info(("Selected entry: %s"):format(result))
        LAST_CMD = result
        Snacks.notify.info((("executing: [%s]"):format(LAST_CMD)))
        term_utils.run_in_terminal(LAST_CMD)
        -- Snacks.terminal()
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
