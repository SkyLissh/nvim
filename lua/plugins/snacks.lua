-- snacks.nvim tweaks on top of LazyVim's defaults.
--
-- LazyVim's explorer (`<leader>e`) delegates to the snacks.picker `explorer`
-- source, whose `hidden`/`ignored` options default to false. Enable them here so
-- the tree shows dotfiles (`.git`, `.env`, ...) and gitignored paths by default.
--
-- Still toggleable at runtime from the explorer window:
--   H -> toggle hidden files
--   I -> toggle ignored files
-- (`h` closes a directory, so it must be Shift-H.)
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}
