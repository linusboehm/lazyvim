return {
  {
    "folke/noice.nvim",
    opts = {
      routes = {
        { filter = { event = "msg_show", find = "search hit BOTTOM" }, skip = true },
        { filter = { event = "msg_show", find = "search hit TOP" }, skip = true },
        { filter = { event = "notify", find = "# Config Change Detected" }, skip = true },
        -- { filter = { event = "msg_show", find = "E486: Pattern not found:" }, stop = true },
        { filter = { event = "msg_show", find = "E486: Pattern not found:" }, view = "mini" },
        { filter = { event = "msg_show", find = vim.fn.expand("%") }, view = "mini" },
        { filter = { event = "msg_show", kind = "search_count" }, skip = true },
        { filter = { event = "msg_show", kind = "", find = "written" }, opts = { skip = true } },
        { filter = { event = "msg_show", kind = "vim.fn.undotree" }, view = "messages" },
        -- { filter = { event = "msg_showmode" }, view = "cmdline", },
      },
    },
  },
}
