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
        -- no auto right-side "flutter logs" window: it duplicates what already
        -- shows in the dap-ui console/repl on every :FlutterRun (debugger runner).
        -- Re-enable if you run flutter without the debugger (logs only go there).
        dev_log = { enabled = false },
        lsp = {
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            renameFilesWithClasses = "always",
          },
        },
      })

      -- Register the dart adapter + launch configs for the plain DAP flow
      -- (<leader>dc / :lua require('dap').continue()) once nvim-dap loads.
      -- Mirrors what flutter-tools only registers at :FlutterRun time.
      -- Resolves the same paths as flutter-tools (fvm-aware).
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyLoad",
        callback = function(event)
          if event.data ~= "nvim-dap" then
            return
          end
          local dap = require("dap")
          require("flutter-tools.executable").get(function(paths)
            -- outside a flutter project / without an SDK, nothing to register
            if not paths or not paths.flutter_bin then
              return
            end
            dap.adapters.dart = {
              type = "executable",
              command = paths.flutter_bin,
              args = { "debug-adapter" },
            }
            dap.configurations.dart = {
              {
                type = "dart",
                request = "launch",
                name = "Launch flutter",
                dartSdkPath = paths.dart_sdk,
                flutterSdkPath = paths.flutter_sdk,
                program = "lib/main.dart",
              },
              {
                type = "dart",
                request = "attach",
                name = "Connect flutter",
                dartSdkPath = paths.dart_sdk,
                flutterSdkPath = paths.flutter_sdk,
                program = "lib/main.dart",
              },
            }
            -- hot reload/restart from the debug console (repl)
            local repl = require("dap.repl")
            repl.commands = vim.tbl_extend("force", repl.commands, {
              custom_commands = {
                [".hot-reload"] = function()
                  dap.session():request("hotReload")
                end,
                [".hot-restart"] = function()
                  dap.session():request("hotRestart")
                end,
              },
            })
          end)
        end,
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
