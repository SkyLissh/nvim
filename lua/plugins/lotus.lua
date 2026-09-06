-- Lotus colorscheme (standalone plugin at ~/Development/lotus.nvim).
-- Swap `dir` for a git URL once the theme is published.
return {
  {

    "SkyLissh/lotus.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "dark",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "lotus_dark" },
  },
}
