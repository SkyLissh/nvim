return {
  {
    "vyfor/cord.nvim",
    opts = {
      buttons = {
        label = function(opts)
          return opts.repo_url and "View Repository" or "Check Github"
        end,
        url = function(opts)
          return opts.repo_url or "https://www.github.com/SkyLissh" -- Only show repo if url available otherwise show github
        end,
      },
      text = {
        editing = function(opts)
          return string.format("Editing %s:%d:%d", opts.filename, opts.cursor_line, opts.cursor_char)
        end,
        workspace = function(opts)
          return "Project: " .. opts.workspace
        end,
        terminal = function(opts)
          return "Doin' black magic (" .. opts.name .. ")"
        end,
      },
      display = {
        theme = "default",
        flavor = "accent",
        view = "full",
      },
      advanced = {
        discord = {
          reconnect = {
            enabled = true,
          },
        },
      },
    },
  },
}
