-- Lotus colorscheme (standalone plugin at ~/Development/lotus.nvim).
-- Swap `dir` for a git URL once the theme is published.
return {
  {
    dir = "~/Development/lotus.nvim",
    name = "lotus",
    lazy = false, -- on the rtp before LazyVim applies the colorscheme
    priority = 1000,
    opts = { style = "dark" }, -- auto-calls require("lotus").setup(opts)
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "lotus_dark" },
  },
}