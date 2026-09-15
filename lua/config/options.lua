-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
--
local opt = vim.opt
opt.wrap = true

-- Neovide: the font comes from ~/.config/neovide/config.toml, but scale and
-- line spacing are nvim-side options only (no config.toml equivalent).
if vim.g.neovide then
  vim.g.neovide_scale_factor = 1.0
  vim.opt.linespace = -1 -- tighten default leading; -2/-3 for tighter, 0 to undo
end
