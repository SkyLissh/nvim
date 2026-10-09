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

      -- "Warm server" cleanup on save: instead of spawning `dart fix` (a fresh
      -- analyzer process per save -> slow, plus external disk writes that trip
      -- Neovim's "file changed on disk" reload prompt), reuse the already
      -- running dartls through LSP. Same source actions as VS Code's Dart
      -- extension `editor.codeActionsOnSave`:
      --   source.fixAll          -> lint fixes (the same set as `dart fix`)
      --   source.organizeImports -> sort / remove imports
      -- dartls answers with a server command whose edits land asynchronously
      -- on the BUFFER (never the disk); Neovim persists them with a guarded
      -- follow-up write. Actions are chained one per save cycle: requesting
      -- both at once makes the server compute the second edit against stale
      -- offsets, which corrupts text.

      local dart_state = {} ---@type table<number, string|nil>

      local function dartls_attached(buf)
        return not vim.tbl_isempty(vim.lsp.get_clients({ bufnr = buf, name = "dartls" }))
      end

      local function dart_action(buf, kinds)
        pcall(vim.lsp.buf.code_action, {
          context = { only = kinds, diagnostics = {} },
          apply = true,
          bufnr = buf,
        })
      end

      -- The server applies its edits asynchronously; poll briefly and write
      -- once they land (the BufWritePost of that write advances the pipeline).
      local function dart_save_when_dirty(buf)
        local attempts = 0
        local function tick()
          if not vim.api.nvim_buf_is_valid(buf) then
            return
          end
          if vim.bo[buf].modified then
            vim.api.nvim_buf_call(buf, function()
              vim.cmd("silent! write")
            end)
            return
          end
          attempts = attempts + 1
          if attempts < 20 then
            vim.defer_fn(tick, 200)
          end
        end
        vim.defer_fn(tick, 200)
      end

      local group = vim.api.nvim_create_augroup("user-dart", { clear = true })

      -- drop per-buffer state when the buffer goes away
      vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        callback = function(args)
          dart_state[args.buf] = nil
        end,
      })

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = "*.dart",
        callback = function(args)
          local buf = args.buf
          if vim.bo[buf].buftype ~= "" or not dartls_attached(buf) then
            return
          end
          local phase = dart_state[buf]
          if phase == "organize" then
            -- final internal write: pipeline complete
            dart_state[buf] = nil
            return
          end
          -- 300ms defer so the server has seen the saved version before the
          -- next edit set is computed (avoids stale-offset edits)
          local function step(kinds)
            return function()
              if not vim.api.nvim_buf_is_valid(buf) then
                return
              end
              dart_action(buf, kinds)
              dart_save_when_dirty(buf)
            end
          end
          if phase == "fix_all" then
            dart_state[buf] = "organize"
            vim.defer_fn(step({ "source.organizeImports" }), 300)
          else
            dart_state[buf] = "fix_all"
            vim.defer_fn(step({ "source.fixAll" }), 300)
          end
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
