return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- LazyVim's own option (not a lspconfig one): disables its
      -- textDocument/inlayHint auto-enable handler, so hints default to off.
      inlay_hints = {
        enabled = false,
      },
    },
  },
}
