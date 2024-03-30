return {
  "ThePrimeagen/harpoon",
  event = "VeryLazy",
  keys = {
    { "<leader>H", false },
    { "<leader>h", false },
    {
      "<leader>ha",
      function()
        require("harpoon"):list():append()
      end,
      desc = "Harpoon File",
    },
    {
      "<leader>hh",
      function()
        require("harpoon").ui:toggle_quick_menu(harpoon:list())
      end,
      desc = "Harpoon Quick Menu",
    },
    {
      "<leader>hp",
      function()
        require("harpoon"):list():prev()
      end,
    },
    {
      "<leader>hn",
      function()
        require("harpoon"):list():next()
      end,
    },
  },
}
