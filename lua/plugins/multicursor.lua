-- multicursor.nvim — multiple cursors the vim way.
--
-- Keybinds (chosen to not collide with LazyVim 16 defaults):
--   <A-J> / <A-K>        add cursor above/below (A-j/A-k are LazyVim "move line",
--                        so the shift variant sits one step up on the same keys)
--   <leader>mc group     everything else; <leader>mc is free (scala extra not loaded)
--   layer keys           apply only while >1 cursor exists → can't conflict
--
-- VS Code parity where it maps cleanly:
--   mcn ~ Ctrl+D (add next match)   mca ~ Ctrl+Shift+L (add all matches)
return {
  {
    "jake-stewart/multicursor.nvim",
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      -- Inherit the colorscheme's groups (lotus) instead of hardcoding colors.
      local hl = vim.api.nvim_set_hl
      hl(0, "MultiCursorCursor", { reverse = true })
      hl(0, "MultiCursorVisual", { link = "Visual" })
      hl(0, "MultiCursorSign", { link = "SignColumn" })
      hl(0, "MultiCursorMatchPreview", { link = "Search" })
      hl(0, "MultiCursorDisabledCursor", { reverse = true })
      hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
      hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })

      -- Layer: keymaps that only exist while there are multiple cursors.
      mc.addKeymapLayer(function(layerSet)
        layerSet({ "n", "x" }, "<left>", mc.prevCursor) -- cycle main cursor
        layerSet({ "n", "x" }, "<right>", mc.nextCursor)
        layerSet({ "n", "x" }, "<BS>", mc.deleteCursor) -- drop the main cursor
        layerSet({ "n", "x" }, "<esc>", function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end)
      end)
    end,
    keys = {
      { "<leader>mc", group = "multi-cursor" }, -- which-key group label
      -- add cursors (normal + visual)
      { "<A-J>", function() require("multicursor-nvim").lineAddCursor(-1) end, desc = "Add cursor above", mode = { "n", "x" } },
      { "<A-K>", function() require("multicursor-nvim").lineAddCursor(1) end, desc = "Add cursor below", mode = { "n", "x" } },
      -- match word/selection
      { "<leader>mcn", function() require("multicursor-nvim").matchAddCursor(1) end, desc = "Add next match", mode = { "n", "x" } },
      { "<leader>mcp", function() require("multicursor-nvim").matchAddCursor(-1) end, desc = "Add prev match", mode = { "n", "x" } },
      { "<leader>mca", function() require("multicursor-nvim").matchAllAddCursors() end, desc = "Add all matches", mode = { "n", "x" } },
      { "<leader>mcs", function() require("multicursor-nvim").matchSkipCursor(1) end, desc = "Skip next match", mode = { "n", "x" } },
      { "<leader>mcS", function() require("multicursor-nvim").matchSkipCursor(-1) end, desc = "Skip prev match", mode = { "n", "x" } },
      { "<leader>mcl", function() require("multicursor-nvim").clearCursors() end, desc = "Clear cursors", mode = { "n", "x" } },
      { "<leader>mct", function() require("multicursor-nvim").toggleCursor() end, desc = "Toggle cursors", mode = { "n", "x" } },
    },
  },
}