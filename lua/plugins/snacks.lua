local term_utils = require("util.toggletem_utils")
LAST_CMD = nil

local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

function SearchBashHistory()
        Snacks.notify.info("running search!")
  require("telescope.builtin").find_files({
    prompt_title = "Search Bash History",
    cwd = "~",
    find_command = { "bash", "-c", "awk '!count[$0]++' ~/.bash_history | tac" },
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
  opts = {
    bigfile = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    quickfile = { enabled = true },
    statuscolumn = { enabled = true },
    words = { enabled = true },
    styles = {
      notification = {
        wo = { wrap = true } -- Wrap notifications
      }
    }
  },
  keys = {
    { "<leader>tc", function() SearchBashHistory() end, desc = "pick terminal command" },
    { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
    { "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
    { "<leader>gg", function() Snacks.lazygit() end, desc = "Lazygit" },
    { "<leader>gb", function() Snacks.git.blame_line() end, desc = "Git Blame Line" },
    { "<leader>gB", function() Snacks.gitbrowse() end, desc = "Git Browse" },
    { "<leader>gf", function() Snacks.lazygit.log_file() end, desc = "Lazygit Current File History" },
    { "<leader>gl", function() Snacks.lazygit.log() end, desc = "Lazygit Log (cwd)" },
    { "<leader>cR", function() Snacks.rename() end, desc = "Rename File" },
    { "<c-/>",      function() Snacks.terminal() end, desc = "Toggle Terminal" },
    { "<leader>th", function() Snacks.terminal("htop") end, desc = "Terminal htop" },
    { "<leader>tp", function() Snacks.terminal("python3") end, desc = "Terminal python" },
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
          -- Snacks.terminal()
          term_utils.run_in_terminal(LAST_CMD)
        end
      end,
      desc = "Terminal python",
    },
    { "<c-_>",      function() Snacks.terminal() end, desc = "which_key_ignore" },
    { "]]",         function() Snacks.words.jump(vim.v.count1) end, desc = "Next Reference" },
    { "[[",         function() Snacks.words.jump(-vim.v.count1) end, desc = "Prev Reference" },
    {
      "<leader>N",
      desc = "Neovim News",
      function()
        Snacks.win({
          file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
          width = 0.6,
          height = 0.6,
          wo = {
            spell = false,
            wrap = false,
            signcolumn = "yes",
            statuscolumn = " ",
            conceallevel = 3,
          },
        })
      end,
    }
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...)
          Snacks.debug.inspect(...)
        end
        _G.bt = function()
          Snacks.debug.backtrace()
        end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
        Snacks.toggle.treesitter():map("<leader>uT")
        Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
        Snacks.toggle.inlay_hints():map("<leader>uh")
      end,
    })
  end,
}

