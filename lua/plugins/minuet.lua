return {
  {
    "milanglacier/minuet-ai.nvim",
    config = function()
      ---@cast opts minuet.Config
      require("minuet").setup({
        provider = "openai_fim_compatible",

        -- Gate ALL auto-triggers behind a real buffer check. auto_trigger_ft = "*"
        -- matches every FileType event, including prompt buffers (picker search,
        -- grep input, explorer rename/new-file, snacks input: buftype=prompt) and
        -- terminals, and minuet's virtualtext path only checks an ft flag by
        -- default — no buftype guard. Cheap check, runs before every request.
        -- Manual <A-y> still works: blink/cmp bypass predicates for manual
        -- triggers (blink.lua: `not_manual_completion`).
        enable_predicates = {
          function()
            return vim.bo.buftype == "" and vim.bo.modifiable
          end,
        },

        -- 1 request per trigger (3 would triple GPU-seconds); more would
        -- just duplicate the same FIM generation on a local 7B.
        n_completions = 1,

        -- chars, not tokens. Ollama prefills the WHOLE window on every
        -- request, so this is the biggest per-request GPU-spike knob.
        -- 2048 chars ~= 500 tokens: enough for local scope + neighbours
        -- on the 7B; was 8000 (~2000 tok prefill = a long 100% GPU grind).
        context_window = 2048,
        context_ratio = 0.75,

        request_timeout = 2.5,
        -- Two gates, applied in order: debounce (idle ms after last
        -- keystroke) then throttle (min gap between fired requests).
        -- Raised so we only ask after a genuine pause, and never refire
        -- while you're still typing. Continuous typing now fires nothing;
        -- a stop to think fires one request, then it stays quiet for 3s.
        debounce = 800,
        throttle = 3000,

        add_single_line_entry = true,

        notify = "debug",

        virtualtext = {
          auto_trigger_ft = { "*" },
          -- Non-code buffers: a prose-writing base model burns GPU cycles to
          -- emit junk. Skip markdown, commits, help, file-manager, etc.
          -- Manual completion (MinuetBlink/C-m or <A-y> blink source) still
          -- works there.
          auto_trigger_ignore_ft = {
            "markdown",
            "text",
            "gitcommit",
            "help",
            "man",
            "oil",
            "qf",
            "checkhealth",
            "NvimTree",
            "neo-tree",
            "avante",
            "dashboard",
            "alpha",
          },
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
