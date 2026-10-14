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

      -- Fix-on-save: on every user save of a *.dart buffer with dartls
      -- attached, request the `source.fixAll` code action (the same fixes as
      -- `dart fix`, and VS Code's source.fixAll on-save action).
      --
      -- dartls applies its fixes asynchronously through workspace/applyEdit,
      -- so the follow-up write only happens once a server edit has actually
      -- landed on the buffer (tracked by wrapping that handler) -- never on a
      -- timer, and never just because the buffer happens to be modified.
      -- The internal write re-enters BufWritePre, where LazyVim formats the
      -- fixed buffer through dartls (see section 3 below).
      --
      -- Generated files (*.g.dart, *.freezed.dart, ...) skip the fix step:
      -- build_runner regenerates them, so fixing them only churns diffs.
      -- They are still formatted when saved, since format-on-save is not
      -- filtered here.

      local FIX_POLL_MS, FIX_ATTEMPTS = 100, 20
      local fix_landed = {} ---@type table<number, number> bufnr -> time of last applied server edit
      local internal_write = {} ---@type table<number, boolean>
      local pending = {} ---@type table<number, boolean>

      -- track when the server applies an edit to a buffer, so the follow-up
      -- write is driven by real edits and not by a timer
      local orig_apply_edit = vim.lsp.handlers["workspace/applyEdit"]
      vim.lsp.handlers["workspace/applyEdit"] = function(err, params, ctx, config)
        if params and params.edit then
          local uris = {}
          local edit = params.edit
          if edit.documentChanges then
            for _, dc in ipairs(edit.documentChanges) do
              if dc.textDocument then
                uris[#uris + 1] = dc.textDocument.uri
              end
            end
          elseif edit.changes then
            for uri in pairs(edit.changes) do
              uris[#uris + 1] = uri
            end
          end
          for _, uri in ipairs(uris) do
            fix_landed[vim.uri_to_bufnr(uri)] = vim.uv.now()
          end
        end
        return orig_apply_edit(err, params, ctx, config)
      end

      local function is_generated(path)
        return path:match("%.g%.dart$")
          or path:match("%.freezed%.dart$")
          or path:match("%.gr%.dart$")
          or path:match("%.mocks%.dart$")
          or path:match("%.config%.dart$")
          or path:match("%.chopper%.dart$")
      end

      local function dartls_attached(buf)
        return not vim.tbl_isempty(vim.lsp.get_clients({ bufnr = buf, name = "dartls" }))
      end

      local function request_fix_all(buf)
        pending[buf] = true
        local requested_at = vim.uv.now()
        vim.lsp.buf.code_action({
          context = { only = { "source.fixAll" }, diagnostics = {} },
          apply = true,
          bufnr = buf,
        })
        -- the edit lands asynchronously: poll briefly, and write only once a
        -- server edit has arrived (then BufWritePre formats before the write)
        local function write_if_fixed(attempt)
          if not vim.api.nvim_buf_is_valid(buf) or not pending[buf] then
            return
          end
          if fix_landed[buf] and fix_landed[buf] >= requested_at then
            pending[buf] = nil
            internal_write[buf] = true
            vim.api.nvim_buf_call(buf, function()
              vim.cmd("silent! write")
            end)
            return
          end
          if attempt < FIX_ATTEMPTS then
            vim.defer_fn(function()
              write_if_fixed(attempt + 1)
            end, FIX_POLL_MS)
          else
            pending[buf] = nil -- no fix came back: nothing to write
          end
        end
        vim.defer_fn(function()
          write_if_fixed(1)
        end, FIX_POLL_MS)
      end

      local group = vim.api.nvim_create_augroup("user-dart", { clear = true })

      -- drop per-buffer state when the buffer goes away
      vim.api.nvim_create_autocmd("BufWipeout", {
        group = group,
        callback = function(args)
          fix_landed[args.buf] = nil
          internal_write[args.buf] = nil
          pending[args.buf] = nil
        end,
      })

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = "*.dart",
        callback = function(args)
          local buf = args.buf
          if internal_write[buf] then
            -- our own follow-up write: pipeline complete
            internal_write[buf] = nil
            return
          end
          if pending[buf] -- one chain at a time per buffer
            or vim.bo[buf].buftype ~= ""
            or is_generated(vim.api.nvim_buf_get_name(buf))
            or not dartls_attached(buf)
          then
            return
          end
          -- small defer so the server has seen the saved version before the
          -- fixes are computed (avoids stale-offset edits)
          vim.defer_fn(function()
            if vim.api.nvim_buf_is_valid(buf) and not pending[buf] then
              request_fix_all(buf)
            end
          end, 300)
        end,
      })

    end,
  },

  -- 3. no conform formatter for dart: dartls already provides
  -- textDocument/formatting, so LazyVim formats every save through the LSP
  -- (no dart_format temp file next to the source, no extra dart process).
  -- LazyVim's dart extra registers dart_format, and list-valued opts merge,
  -- so this needs an opts function that nils the entry out.
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.dart = nil
    end,
  },
}
