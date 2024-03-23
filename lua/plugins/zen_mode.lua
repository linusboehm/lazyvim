return {
  "folke/zen-mode.nvim",
  opts = {
    window = {
      backdrop = 0.15, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
      -- height and width can be:
      -- * an absolute number of cells when > 1
      -- * a percentage of the width / height of the editor when <= 1
      -- * a function that returns the width or the height
      width = 120, -- width of the Zen window
      height = 1, -- height of the Zen window
      -- by default, no options are changed for the Zen window
      -- uncomment any of the options below, or add other vim.wo options you want to apply
      options = {
        -- signcolumn = "no", -- disable signcolumn
        -- number = false, -- disable number column
        -- relativenumber = false, -- disable relative numbers
        -- cursorline = false, -- disable cursorline
        -- cursorcolumn = false, -- disable cursor column
        -- foldcolumn = "0", -- disable fold column
        -- list = false, -- disable whitespace characters
      },
    },
    plugins = {
      -- disable some global vim options (vim.o...)
      -- comment the lines to not apply the options
      options = {
        enabled = true,
        ruler = false, -- disables the ruler text in the cmd line area
        showcmd = false, -- disables the command in the last line of the screen
        -- you may turn on/off statusline in zen mode by setting 'laststatus'
        -- statusline will be shown only if 'laststatus' == 3
        laststatus = 3, -- turn off the statusline in zen mode
      },
      -- twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
      gitsigns = { enabled = false }, -- disables git signs
      -- tmux = { enabled = false }, -- disables the tmux statusline
    },
    -- callback where you can add custom code when the Zen window opens
    on_open = function(win)
      if vim.bo.filetype == "toggleterm" then
        local maxWidth = vim.o.columns -- The total width of the Neovim instance
        local maxHeight = vim.o.lines - 5
        vim.api.nvim_win_set_width(win, maxWidth)
        vim.api.nvim_win_set_height(win, maxHeight)
        -- vim.api.nvim_command("colorscheme terafox")
      end
      -- vim.cmd("AerialOpen")
    end,
    -- callback where you can add custom code when the Zen window closes
    -- on_close = function()
    --   vim.api.nvim_command("colorscheme nightfox")
    -- end,
  },
  keys = { { mode = { "n" }, "<leader>uz", "<cmd>ZenMode<cr>", { desc = "zen mode" } } },
}
