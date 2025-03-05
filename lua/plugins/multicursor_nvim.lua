return {
  "jake-stewart/multicursor.nvim",
  branch = "1.0",
  opts = {
    vim.keymap.set({ "n", "x" }, "mw", function()
      local mc = require("multicursor-nvim")
      mc.operator({ motion = "iw", visual = true })
      -- Or you can pass a pattern, press `mwi{` will select every \w,
      -- basically every char in a `{ a, b, c, d }`.
      -- mc.operator({ pattern = [[\<\w]] })
    end),
  },
  keys = function()
    local mc = require("multicursor-nvim")

    return {
      {
        "<up>",
        function()
          mc.lineAddCursor(-1)
        end,
        desc = "Add cursors above the main cursor",
        mode = { "n", "v" },
      },
      {
        "<down>",
        function()
          mc.lineAddCursor(1)
        end,
        desc = "Add cursors bellow the main cursor",
        mode = { "n", "v" },
      },
      {
        "<s-up>",
        function()
          mc.lineSkipCursor(-1)
        end,
        desc = "Add cursors above the main cursor",
        mode = { "n", "v" },
      },
      {
        "<s-down>",
        function()
          mc.lineSkipCursor(1)
        end,
        desc = "Add cursors bellow the main cursor",
        mode = { "n", "v" },
      },
      -- {
      --   "<c-n>",
      --   function()
      --     mc.addCursor "*"
      --   end,
      --   desc = "Jump to the next word under cursor but do not add a cursor",
      --   mode = { "n", "v" },
      -- },
      -- {
      --   "<c-s>",
      --   function()
      --     mc.skipCursor "*"
      --   end,
      --   desc = "Jump to the next word under cursor but do not add a cursor",
      --   mode = { "n", "v" },
      -- },
      {
        "<left>",
        mc.nextCursor,
        desc = "Move cursor left",
        mode = { "n", "v" },
      },
      {
        "<right>",
        mc.prevCursor,
        desc = "Move cursor right",
        mode = { "n", "v" },
      },
      {
        "<leader>mx",
        mc.deleteCursor,
        desc = "Delete main cursor",
        mode = { "n", "v" },
      },
      {
        "<leader>mr",
        mc.restoreCursors,
        desc = "Restore cursors",
      },
      -- {
      --   "<leader>mr",
      --   mc.visualToCursors(),
      --   desc = "Visual to cursors",
      --   mode = { "n", "v" },
      -- },
      {
        "<c-leftmouse>",
        mc.handleMouse,
        desc = "Add cursor",
        mode = { "n" },
      },
      {
        "<c-q>",
        function()
          if mc.cursorsEnabled() then
            -- Stop other cursors from moving.
            -- This allows you to reposition the main cursor.
            mc.disableCursors()
          else
            mc.addCursor()
          end
        end,
        desc = "Stop sub curosors from moving",
        mode = { "n", "v" },
      },
      {
        "<esc>",
        function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          elseif mc.hasCursors() then
            mc.clearCursors()
          else
            vim.cmd("noh")
          end
        end,
        desc = "Clear cursors",
        mode = { "n" },
      },
      {
        "<leader>ma",
        mc.alignCursors,
        desc = "Align Cursor Columns",
        mode = { "n" },
      },
      {
        "<leader>ms",
        mc.splitCursors,
        desc = "Split visual selection by regex",
        mode = { "v" },
      },
      {
        "<leader>mI",
        mc.insertVisual,
        desc = "Insert for each line of visual selection",
        mode = { "v" },
      },
      {
        "<leader>mA",
        mc.appendVisual,
        desc = "Append for each line of visual selection",
        mode = { "v" },
      },
      {
        "<leader>mM",
        mc.matchCursors,
        desc = "match new cursors within visual selection regex",
        mode = { "v" },
      },
      {
        "<leader>mt",
        function()
          mc.transposeCursors(1)
        end,
        desc = "Rotate visual selection contents",
        mode = { "v" },
      },
      -- {
      --   "<leader>mT",
      --   function()
      --     mc.transposeCursors(-1)
      --   end,
      --   desc = "Rotate visual selection contents",
      --   mode = { "v" },
      -- },
      {
        "<leader>ms",
        function()
          mc.searchAllAddCursors()
        end,
        desc = "add cursors to search matches",
      },
      { "g<c-a>", mc.sequenceIncrement, mode = { "n", "x" } },
      { "g<c-x>", mc.sequenceDecrement, mode = { "n", "x" } },
    }
  end,
  config = function()
    local mc = require("multicursor-nvim")
    mc.setup()
    -- Customize how cursors look.
    vim.api.nvim_set_hl(0, "MultiCursorCursor", { link = "Cursor" })
    vim.api.nvim_set_hl(0, "MultiCursorVisual", { link = "Visual" })
    vim.api.nvim_set_hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
    vim.api.nvim_set_hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
  end,
}
