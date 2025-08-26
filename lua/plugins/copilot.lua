return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },
    cmd = "CopilotChat",
    opts = {
      model = 'claude-sonnet-4',
      mappings = {
        reset = {
          normal = "<C-w>",
          insert = "<C-w>",
        },
      },
    },
    keys = function()
      local select = require("CopilotChat.select")
      -- local snacks_integration = require("CopilotChat.integrations.snacks")
      -- local actions = require("CopilotChat.actions")

      return {
        {
          "<leader>aq",
          function()
            local input = vim.fn.input("Quick Chat: ")
            if input ~= "" then
              require("CopilotChat").ask(input, { selection = select.buffer })
            end
          end,
          desc = "CopilotChat - Quick chat",
        },
        {
          "<leader>aq",
          function()
            local input = vim.fn.input("Quick Chat: ")
            if input ~= "" then
              require("CopilotChat").ask(input, { selection = select.visual })
            end
          end,
          desc = "CopilotChat - Quick chat",
          mode = "v",
        },
        -- {
        --   "<leader>ap",
        --   function()
        --     snacks_integration.pick(actions.prompt_actions(), { selection = select.buffer, layout = "dropdown" })
        --   end,
        --   desc = "CopilotChat - Prompt actions",
        -- },
        -- {
        --   "<leader>ap",
        --   function()
        --     snacks_integration.pick(actions.prompt_actions(), { selection = select.visual, layout = "dropdown" })
        --   end,
        --   desc = "CopilotChat - Prompt actions",
        --   mode = "v",
        -- },
        {
          "<leader>am",
          "<cmd>CopilotChatCommit<cr>",
          desc = "CopilotChat - Generate commit message for all changes",
        },
        {
          "<leader>aM",
          "<cmd>CopilotChatCommitStaged<cr>",
          desc = "CopilotChat - Generate commit message for staged changes",
        },
      }
    end,
  },
}
