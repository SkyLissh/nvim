return {
  {
    "milanglacier/minuet-ai.nvim",
    config = function()
      ---@cast opts minuet.Config
      require("minuet").setup({
        provider = "openai_fim_compatible",

        -- 3 parallel requests = 3x identical GPU generation per trigger
        -- (and up to ~3s wall on the 7B). 1 cuts GPU-seconds ~3x.
        n_completions = 1,

        -- NOTE: chars, not tokens. Default 16000. Input dominates cost +
        -- latency on a chat endpoint, so this is the real budget knob.
        context_window = 8000,
        context_ratio = 0.75,

        request_timeout = 2.5,
        throttle = 1200, -- min interval while typing; the knob that binds
        debounce = 450, -- general floor; largely redundant under throttle

        add_single_line_entry = true,

        notify = "debug",

        virtualtext = {
          auto_trigger_ft = { "*" },
          show_on_completion_menu = true,
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
          openai_fim_compatible = {
            api_key = "TERM", -- env var NAME, not the value
            end_point = "http://localhost:11434/v1/completions",
            model = "qwen2.5-coder:7b-base",
            name = "Ollama",
            optional = {
              -- 256 = max GPU burn per request; 128 halves it while still
              -- covering most single-line/multi-line inline completions.
              -- Raise only if completions feel timid.
              max_tokens = 128,
              top_p = 0.9,
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
