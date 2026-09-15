-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Global (all buffers) inlay hints toggle, replaces LazyVim's per-buffer
-- <leader>uh. Omitted {bufnr} filter = global scope in nvim >= 0.11.
Snacks.toggle.inlay_hints({
  name = "Inlay Hints",
  get = function()
    return vim.lsp.inlay_hint.is_enabled()
  end,
  set = function(state)
    vim.lsp.inlay_hint.enable(state)
  end,
}):map("<leader>uh")
