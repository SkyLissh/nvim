-- VSCodium (vscode-neovim) overrides.
--
-- The auto-enabled `vscode` extra disables LazyVim's snacks picker and all of
-- its LSP plumbing, so two families of LazyVim chords are dead under VSCodium:
--   * picker chords (LazyVim.pick / Snacks.picker.*) have no picker to call
--   * LSP + diagnostic chords are buffer-local, set on nvim's LspAttach, which
--     never fires because the language servers run in VS Code, not nvim
-- Route them to the equivalent VS Code commands instead.
--
-- Reuses the same LazyVimKeymapsDefaults hook the extra itself uses, so these
-- mappings win over LazyVim's defaults.
if not vim.g.vscode then
  return {}
end

vim.api.nvim_create_autocmd("User", {
  pattern = "LazyVimKeymapsDefaults",
  callback = function()
    local vscode = require("vscode")

    local function call(command)
      return function()
        vscode.action(command)
      end
    end

    local map = vim.keymap.set
    local problems = "workbench.actions.view.problems"

    -- picker + explorer chords -> VS Code finders / panels
    -- (<leader>e remaps to <leader>fe in LazyVim, so both need overriding)
    local pickers = {
      { "<leader>,", "Buffers", "workbench.action.showAllEditors" },
      { "<leader>:", "Command History", "workbench.action.showCommands" },
      { "<leader>ff", "Find Files", "workbench.action.quickOpen" },
      { "<leader>fF", "Find Files (cwd)", "workbench.action.quickOpen" },
      { "<leader>fg", "Find Files (git-files)", "workbench.action.quickOpen" },
      { "<leader>fr", "Recent", "workbench.action.openRecent" },
      { "<leader>fR", "Recent (cwd)", "workbench.action.openRecent" },
      { "<leader>fb", "Buffers", "workbench.action.showAllEditors" },
      { "<leader>fB", "Buffers (all)", "workbench.action.showAllEditors" },
      { "<leader>fc", "Find Config File", "workbench.action.openSettingsJson" },
      { "<leader>fp", "Projects", "workbench.action.openRecent" },
      { "<leader>sb", "Buffer Lines", "actions.find" },
      { "<leader>sB", "Grep Open Buffers", "workbench.action.findInFiles" },
      { "<leader>sg", "Grep (Root Dir)", "workbench.action.findInFiles" },
      { "<leader>sG", "Grep (cwd)", "workbench.action.findInFiles" },
      { "<leader>sC", "Commands", "workbench.action.showCommands" },
      { "<leader>sc", "Command History", "workbench.action.showCommands" },
      { "<leader>sd", "Diagnostics", problems },
      { "<leader>sD", "Buffer Diagnostics", problems },
      { "<leader>sl", "Location List", problems },
      { "<leader>sq", "Quickfix List", problems },
      { "<leader>sh", "Help Pages", "workbench.action.openDocumentationUrl" },
      { "<leader>sk", "Keymaps", "workbench.action.openGlobalKeybindings" },
      { "<leader>sp", "Plugin Specs", "workbench.view.extensions" },
      { "<leader>sS", "LSP Workspace Symbols", "workbench.action.showAllSymbols" },
      { "<leader>uC", "Colorschemes", "workbench.action.selectTheme" },
      -- Snacks toggles act on nvim state that VS Code owns, so they do nothing here
      { "<leader>uw", "Word Wrap", "editor.action.toggleWordWrap" },
      { "<leader>ub", "Dark/Light Background", "workbench.action.toggleLightDarkThemes" },
      { "<leader>wm", "Zoom", "workbench.action.toggleMaximizeEditorGroup" },
      { "<leader>e", "Explorer (Root Dir)", "workbench.view.explorer" },
      { "<leader>E", "Explorer (cwd)", "workbench.view.explorer" },
      { "<leader>fe", "Explorer (Root Dir)", "workbench.view.explorer" },
      { "<leader>fE", "Explorer (cwd)", "workbench.view.explorer" },
      { "<leader>gd", "Git Diff (hunks)", "workbench.view.scm" },
      { "<leader>gD", "Git Diff (origin)", "workbench.view.scm" },
      { "<leader>gs", "Git Status", "workbench.view.scm" },
    }
    for _, p in ipairs(pickers) do
      map("n", p[1], call(p[3]), { desc = p[2] .. " (VS Code)" })
    end

    -- Not mapped on purpose (no VS Code counterpart):
    --   <leader>n, s", s/, sa, sH, si, sj, sm, sM, sR, st, sT, su, sw, sW,
    --   gS, gi, gp, gai, gao  -- and <leader>ss, which the extra already maps.

    -- LSP keys (buffer-local in LazyVim; plain `gd` is natively handled by the
    -- extension, so it is left alone)
    map("n", "gr", call("editor.action.referenceSearch.trigger"), { desc = "References (VS Code)", nowait = true })
    map("n", "gI", call("editor.action.goToImplementation"), { desc = "Goto Implementation (VS Code)" })
    map("n", "gy", call("editor.action.goToTypeDefinition"), { desc = "Goto Type Definition (VS Code)" })
    map({ "n", "x" }, "<leader>ca", call("editor.action.quickFix"), { desc = "Code Action (VS Code)" })
    map("n", "<leader>cr", call("editor.action.rename"), { desc = "Rename (VS Code)" })
    map({ "n", "x" }, "<leader>cf", call("editor.action.formatDocument"), { desc = "Format (VS Code)" })
    map("n", "<leader>cd", call("editor.action.showHover"), { desc = "Line Diagnostics (VS Code)" })

    -- diagnostics live in VS Code, so nvim's ]d/[d find nothing to jump to
    map("n", "]d", call("editor.action.marker.next"), { desc = "Next Diagnostic (VS Code)" })
    map("n", "[d", call("editor.action.marker.prev"), { desc = "Prev Diagnostic (VS Code)" })
    map("n", "]q", call("editor.action.marker.nextInFiles"), { desc = "Next Problem in Files (VS Code)" })
    map("n", "[q", call("editor.action.marker.prevInFiles"), { desc = "Prev Problem in Files (VS Code)" })
  end,
})

-- The snacks explorer is an nvim-side tree, which vscode-neovim can only render
-- as a text buffer. Disable it and use VS Code's own explorer instead. (The
-- LazyVim `vscode` extra does not disable it, unlike picker/notifier/etc.)
return {
  { "folke/snacks.nvim", opts = { explorer = { enabled = false } } },
}
