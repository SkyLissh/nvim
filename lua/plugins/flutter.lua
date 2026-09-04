return {
  -- 1. undo what the dart extra did
  {
    "neovim/nvim-lspconfig",
    priority = 1000,
    opts = function(_, opts)
      opts.servers.dartls = nil
    end,
  },

  -- 2. let flutter-tools own dartls, resolved through FVM
  {
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    config = function()
      require("flutter-tools").setup({
        fvm = true, -- uses <root>/.fvm/flutter_sdk
        root_patterns = { ".git", "pubspec.yaml" },
        debugger = { enabled = true }, -- needs lazyvim's dap.core extra
        widget_guides = { enabled = true },
        lsp = {
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            renameFilesWithClasses = "always",
          },
        },
      })
    end,
  },

  -- 3. conform's dart_format also resolves from PATH
  {
    "stevearc/conform.nvim",
    opts = {
      formatters = {
        dart_format = {
          command = function()
            local root = vim.fs.root(0, { ".fvm", "pubspec.yaml" })
            local sdk = root and vim.fs.joinpath(root, ".fvm", "flutter_sdk")
            if sdk and vim.fn.executable(sdk .. "/bin/dart") == 1 then
              return sdk .. "/bin/dart"
            end
            return "dart"
          end,
        },
      },
    },
  },
}
