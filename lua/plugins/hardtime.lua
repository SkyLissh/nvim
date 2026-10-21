return {
  {
    "m4xshen/hardtime.nvim",
    cond = not vim.g.vscode,
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {},
  },
}
