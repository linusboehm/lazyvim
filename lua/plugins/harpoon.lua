local harpoon = require("harpoon")
return {
  "ThePrimeagen/harpoon",
  keys = {
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
    },
    {
      "<leader>hn",
      function()
        harpoon:list():next()
      end,
    },
  },
}
