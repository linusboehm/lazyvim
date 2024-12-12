return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "main",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },
    event = "VeryLazy",
    opts = {},
    keys = function()
      local select = require("CopilotChat.select")
      local telescope = require("CopilotChat.integrations.telescope")
      local actions = require("CopilotChat.actions")

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
        {
          "<leader>ah",
          function()
            telescope.pick(actions.help_actions(), { selection = select.buffer })
          end,
          desc = "CopilotChat - Help actions",
        },
        {
          "<leader>ah",
          function()
            telescope.pick(actions.help_actions(), { selection = select.visual })
          end,
          desc = "CopilotChat - Help actions",
          mode = "v",
        },
        {
          "<leader>ap",
          function()
            telescope.pick(actions.prompt_actions(), { selection = select.visual })
          end,
          desc = "CopilotChat - Prompt actions",
        },
        {
          "<leader>ap",
          function()
            telescope.pick(actions.prompt_actions(), { selection = select.visual })
          end,
          desc = "CopilotChat - Prompt actions",
          mode = "v",
        },
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
