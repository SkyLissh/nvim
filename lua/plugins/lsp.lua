local inlay_hint = require("vim.lsp.inlay_hint")
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hint = {
        enabled = false,
      },
    },
  },
}
