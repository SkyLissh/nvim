-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
local opt = vim.opt
opt.wrap = true

-- Flutter ARB (l10n) files are JSON: own `arb` filetype so the json
-- treesitter parser and jsonls can be attached to it (see lsp.lua).
-- Set here, not in autocmds.lua, so files opened at startup are detected.
vim.filetype.add({
  extension = {
    arb = "arb",
  },
})
vim.treesitter.language.register("json", "arb")
vim.api.nvim_create_autocmd("FileType", {
  pattern = "arb",
  callback = function()
    vim.opt_local.conceallevel = 0 -- same as LazyVim's json fix: show the quotes
  end,
})

-- Neovide: the font comes from ~/.config/neovide/config.toml, but scale and
-- line spacing are nvim-side options only (no config.toml equivalent).
if vim.g.neovide then
  vim.g.neovide_scale_factor = 1.0
  vim.opt.linespace = -1 -- tighten default leading; -2/-3 for tighter, 0 to undo
end
