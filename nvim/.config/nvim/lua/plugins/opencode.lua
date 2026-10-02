return {
  "nickjvandyke/opencode.nvim",
  -- Follow main for OpenCode V2 support (the stable v1 release uses `opencode --port`).
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      select = {
        prompts = {
          names = "Suggest clearer, more descriptive names for the variables and functions in @this. Briefly explain each suggestion without editing the code.",
        },
      },
    }

    -- By default opencode.nvim only targets sessions in Neovim's cwd.
    -- Use the newest root session across all directories instead.
    local server = require("opencode.server")
    function server:get_sessions()
      return self:request("/api/session?order=desc&parentID=null", "GET"):next(function(response)
        return response and response.data or {}
      end)
    end

    -- Relative file references would point at the wrong project in a global session.
    local context = require("opencode.context")
    local format = context.format
    context.format = function(opts)
      local absolute_opts = vim.tbl_extend("force", {}, opts)
      absolute_opts.rel = nil
      return format(absolute_opts)
    end

    -- Recommended/example keymaps
    vim.keymap.set({ "n" }, "<S-C-u>", function()
      require("opencode").command("session.half.page.up")
    end, { desc = "Scroll OpenCode up" })
    vim.keymap.set({ "n" }, "<S-C-d>", function()
      require("opencode").command("session.half.page.down")
    end, { desc = "Scroll OpenCode down" })
  end,
}
