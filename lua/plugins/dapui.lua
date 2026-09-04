-- Minimal debug UI (nvim-dap-ui):
--   layout 1 (bottom): only the REPL "debug console" (flutter/dart logs, eval) — auto-opens
--   layout 2 (right):  variables (scopes/watches/stacks/breakpoints) — on demand only
-- Controls: <leader>du toggles the whole UI, <leader>dv toggles the variables panel.
-- Single elements can be floated anytime with
--   :lua require("dapui").float_element("scopes")  (or "watches", "stacks", "breakpoints")
return {
  {
    "rcarriga/nvim-dap-ui",
    opts = {
      layouts = {
        {
          elements = {
            { id = "repl", size = 1 },
          },
          size = 0.3,
          position = "bottom",
        },
        {
          elements = {
            { id = "scopes", size = 0.35 },
            { id = "watches", size = 0.25 },
            { id = "stacks", size = 0.2 },
            { id = "breakpoints", size = 0.2 },
          },
          size = 45,
          position = "right",
        },
      },
    },
    config = function(_, opts)
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup(opts)
      -- open only the console on debug start; the variables panel stays manual
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open({ layout = 1 })
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close({})
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close({})
      end
    end,
    keys = {
      { "<leader>dv", function() require("dapui").toggle({ layout = 2 }) end, desc = "Toggle Variables Panel" },
    },
  },
}
