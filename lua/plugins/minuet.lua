return {
  {
    "milanglacier/minuet-ai.nvim",
    config = function()
      ---@cast opts minuet.Config
      require("minuet").setup({
        provider = "openai_compatible",

        -- NOTE: chars, not tokens. Default 16000. Input dominates cost +
        -- latency on a chat endpoint, so this is the real budget knob.
        context_window = 20000,
        context_ratio = 0.75,

        request_timeout = 2.5,
        throttle = 1200, -- min interval while typing; the knob that binds
        debounce = 450, -- general floor; largely redundant under throttle

        n_completions = 1,
        add_single_line_entry = true,

        virtualtext = {
          -- Allowlist: default { "*" } fires in markdown/gitcommit/.fvmrc,
          -- which is pure waste. Add backends as needed.
          auto_trigger_ft = {
            "dart",
            "rust",
            "go",
            "lua",
            "typescript",
            "typescriptreact",
            "svelte",
            "html",
            "css",
          },
          keymap = {
            accept = "<A-a>",
            accept_line = "<A-l>",
            accept_n_lines = "<A-n>",
            next = "<A-]>",
            prev = "<A-[>",
            dismiss = "<A-e>",
          },
        },

        provider_options = {
          openai_compatible = {
            api_key = "OPENCODE_GO_API_KEY", -- env var NAME, not the value
            end_point = "https://opencode.ai/zen/go/v1/chat/completions",
            model = "deepseek-v4-flash",
            name = "Opencode",
            optional = {
              max_tokens = 256, -- 56 = the cost-optimized default; raise if too timid
              top_p = 0.9,
              thinking = { type = "disabled" }, -- not optional: reasoning = 1st-token lag
            },
          },
        },
      })
    end,
  },

  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      keymap = {
        -- Manual fallback: same engine, on-demand, costs nothing while idle.
        ["<A-y>"] = {
          function(cmp)
            cmp.show({ providers = { "minuet" } })
          end,
        },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        -- minuet deliberately ABSENT from default: blink would fire a request
        -- on every word char, an order of magnitude more traffic than
        -- virtualtext's throttled auto-trigger.
        providers = {
          minuet = {
            name = "minuet",
            module = "minuet.blink",
            async = true,
            timeout_ms = 3000, -- > request_timeout * 1000
            score_offset = 100,
          },
        },
      },
      completion = {
        trigger = { prefetch_on_insert = false },
      },
    },
  },
}
