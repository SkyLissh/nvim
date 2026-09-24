-- Godot 4 support: GDScript (.gd), scenes (.tscn), resources (.tres),
-- shaders (.gdshader/.gdshaderinc), project file (.godot), extensions
-- (.gdextension)
--
-- Requirements:
--   - Godot editor must be OPEN for the GDScript LSP (it runs inside the
--     editor on port 6005, and applies buffer edits back to the editor).
--   - `gdscript-formatter` is auto-installed by Mason (see below).
--   - Optional (shaders LSP, not in Mason):
--     `go install github.com/godofavacyn/gdshader-lsp@latest`

return {
  -- Treesitter: syntax highlighting for scripts, shaders, scenes/resources
  {
    "nvim-treesitter/nvim-treesitter",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "gdscript",
        "gdshader",
        "godot_resource",
      },
    },
  },

  -- GDScript LSP (connects to the Godot editor on port 6005)
  -- Root is detected via project.godot, which lspconfig already declares.
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = vim.tbl_extend("keep", opts.servers or {}, {
        gdscript = {
          capabilities = {
            -- Godot's LSP advertises textDocument/willSaveWaitUntil without
            -- supporting it, which spams errors otherwise
            textDocument = {
              willSaveWaitUntil = false,
            },
          },
        },
      })
      -- shader LSP is optional (not on Mason); only enable if present
      if vim.fn.executable("gdshader-lsp") == 1 then
        opts.servers.gdshader_lsp = {}
      end
      return opts
    end,
  },

  -- Formatter via Mason: gdscript-formatter (GDQuest, gdformat-compatible)
  {
    "mason-org/mason.nvim",
    opts_extend = { "ensure_installed" },
    opts = {
      ensure_installed = {
        "gdscript-formatter",
      },
    },
  },

  -- gdformat-compatible formatter for .gd files
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        gdscript = { "gdscript-formatter" },
      },
    },
  },

  -- Debug adapter (Godot's DAP server runs inside the editor on port 6006)
  -- Workflow: open the project in the Godot editor, then in Neovim run
  -- `:DapContinue` and pick "Launch current scene" / "Launch project".
  {
    "mfussenegger/nvim-dap",
    opts = function(_, opts)
      local dap = require("dap")
      dap.adapters.godot = {
        type = "server",
        host = "127.0.0.1",
        port = "6006",
      }
      dap.configurations.gdscript = {
        {
          type = "godot",
          request = "launch",
          name = "Launch current scene",
          project = "${workspaceFolder}",
          launch_scene = true,
        },
        {
          type = "godot",
          request = "launch",
          name = "Launch project",
          project = "${workspaceFolder}",
          launch_scene = false,
        },
      }
      return opts
    end,
  },
}
