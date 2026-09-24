-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Godot: parser/filetype mapping, editor settings and run commands
vim.api.nvim_create_augroup("user-godot", { clear = true })

-- Map the `gdresource` filetype (.tscn/.tres) to the `godot_resource`
-- treesitter parser
vim.treesitter.language.register("godot_resource", "gdresource")

-- Neovim's runtime doesn't detect Godot's ini-style files; give them the
-- same `gdresource` filetype as .tscn/.tres (godot_resource highlighting)
vim.filetype.add({
  extension = {
    gdextension = "gdresource",
    godot = "gdresource",
    import = "gdresource",
  },
})

-- these filetypes use '#' comments but ship no commentstring
vim.api.nvim_create_autocmd("FileType", {
  group = "user-godot",
  pattern = { "gdscript", "gdshader" },
  callback = function(args)
    vim.bo[args.buf].commentstring = "# %s"
  end,
})

-- Godot's ConfigFile format (.tscn/.tres/.godot/.gdextension) uses ';'
vim.api.nvim_create_autocmd("FileType", {
  group = "user-godot",
  pattern = "gdresource",
  callback = function(args)
    vim.bo[args.buf].commentstring = "; %s"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = "user-godot",
  pattern = "gdscript",
  callback = function(args)
    -- GDScript is indent-sensitive: 4 spaces, no tabs
    vim.bo[args.buf].expandtab = true
    vim.bo[args.buf].shiftwidth = 4
    vim.bo[args.buf].tabstop = 4
  end,
})

-- Run the project / current scene from a terminal tab
local function godot_term(args)
  vim.cmd("tabnew")
  vim.cmd("term godot --path " .. vim.fn.getcwd() .. " " .. args)
  vim.cmd("startinsert")
end

vim.api.nvim_create_user_command("GodotRun", function()
  godot_term("")
end, { desc = "Run the current Godot project" })

vim.api.nvim_create_user_command("GodotRunScene", function()
  local path = vim.fn.expand("%:p")
  if path:match("%.tscn$") then
    godot_term(vim.fn.shellescape(path))
  else
    godot_term("")
  end
end, { desc = "Run the current scene in Godot" })
