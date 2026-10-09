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

      -- dart format (conform) only normalizes whitespace. Import ordering is
      -- the LSP "Organize Imports" action (source.organizeImports) and quote /
      -- const fixes are lint fixes from `dart fix` -- neither is the formatter,
      -- so wire them up separately (what VS Code's Dart extension does on save).

      -- Mirror the conform resolver: project FVM SDK, then FVM global default,
      -- then whatever `dart` is on PATH.
      local function dart_bin()
        local root = vim.fs.root(0, { ".fvm", "pubspec.yaml" })
        local sdk = root and vim.fs.joinpath(root, ".fvm", "flutter_sdk")
        if sdk and vim.fn.executable(sdk .. "/bin/dart") == 1 then
          return sdk .. "/bin/dart"
        end
        local fvm = vim.env.FVM_HOME or vim.fs.joinpath(vim.env.HOME, "fvm")
        for _, c in ipairs({
          vim.fs.joinpath(fvm, "default", "bin", "dart"),
          vim.fs.joinpath(fvm, "versions", "default", "bin", "dart"),
        }) do
          if vim.fn.executable(c) == 1 then
            return c
          end
        end
        return "dart"
      end

      -- Code cleanup on save: the same source actions VS Code's Dart
      -- extension runs via `editor.codeActionsOnSave` --
      --   source.fixAll          -> edit.fixAll                (lint fixes)
      --   source.organizeImports -> dart.edit.organizeImports (sort/remove imports)
      -- Both are server commands whose edits land asynchronously, so this runs
      -- after the write and writes once more if the buffer changed (guarded).
      local dart_saving = {}

      -- Lint fixes run through the CLI (`dart fix --apply`), which is exactly
      -- what VS Code's Fix All applies. Scoped to the saved file only, and run
      -- async so the analyzer spin-up never blocks the UI.
      local function dart_code_cleanup(buf, file)
        local root = vim.fs.root(buf, { "pubspec.yaml" }) or vim.fn.getcwd()
        vim.system({ dart_bin(), "fix", "--apply", file }, { cwd = root, text = true }, function(res)
          vim.schedule(function()
            if res.code ~= 0 then
              vim.notify("dart fix failed:\n" .. (res.stdout or ""), vim.log.levels.ERROR)
              return
            end
            -- pull the lint fixes back into the buffer when the file changed
            if (res.stdout or ""):match("%d+ fixes? made") then
              vim.cmd("checktime")
            end
            -- organize imports via dartls (sorts + drops unused imports)
            pcall(vim.lsp.buf.code_action, {
              context = { only = { "source.organizeImports" }, diagnostics = {} },
              apply = true,
              bufnr = buf,
            })
          end)
        end)
      end

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("user-dart", { clear = true }),
        pattern = "*.dart",
        callback = function(args)
          if vim.bo[args.buf].buftype ~= "" then
            return
          end
          if dart_saving[args.buf] then
            dart_saving[args.buf] = nil
            return
          end
          pcall(dart_code_cleanup, args.buf, args.file)
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].modified then
              dart_saving[args.buf] = true
              vim.api.nvim_buf_call(args.buf, function()
                vim.cmd("silent! write")
              end)
            end
          end, 1200)
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
