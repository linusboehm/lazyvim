local term_utils = require("util.toggletem_utils")
LAST_CMD = nil

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

function SearchBashHistory()
  Snacks.notify.info("running search!")
  require("telescope.builtin").find_files({
    prompt_title = "Search Bash History",
    cwd = "~",
    find_command = { "bash", "-c", "awk '!/^#/ && !count[$0]++' ~/.bash_history | tac" },
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

-- Add a key mapping to call this function

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = { styles = { terminal = { keys = { gf = false } } } },
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
          --   Snacks.notify.info("getting command")
          SearchBashHistory()
        --   Snacks.notify.info(("getting command: %s"):format(LAST_CMD))
        -- end
        else
          Snacks.notify.info((("executing: [%s]"):format(LAST_CMD)))
          term_utils.run_in_terminal(LAST_CMD)
        end
      end,
      desc = "Terminal python",
    },
  },
}
