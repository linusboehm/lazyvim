local misc_util = require("util.misc")

return {
  "ThePrimeagen/harpoon",
  event = "VeryLazy",
  branch = "harpoon2",


  keys = function()
    local harpoon = require("harpoon")
    local keys = {
      { "<leader>H", false },
      { "<leader>h", false },
      {
        "<leader>ha",
        function()
          harpoon:list():append()
        end,
        desc = "Harpoon File",
      },
      {
        "<leader>hh",
        function()
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon Quick Menu",
      },
      {
        "<leader>hp",
        function()
          harpoon:list():prev()
        end,
        desc = "Harpoon previous",
      },
      {
        "<leader>hn",
        function()
          harpoon:list():next()
        end,
        desc = "Harpoon next",
      },
    }

    for i = 1, 5 do
      table.insert(keys, {
        "<leader>" .. i,
        function()
          if vim.bo.filetype == "aerial" then
            vim.cmd([[wincmd p]])
          end
          harpoon:list():select(i)
        end,
        desc = "Harpoon to File " .. i,
      })
    end
    return keys
  end,
}
