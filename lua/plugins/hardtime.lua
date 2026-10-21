return {
  {
    "m4xshen/hardtime.nvim",
    vscode = true,
    lazy = false,
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = function(_, opts)
      if vim.g.vscode then
        opts.callback = function(text)
          require("vscode").notify("Hardtime: " .. text, vim.log.levels.WARN)
        end
      end
    end,
  },
}
