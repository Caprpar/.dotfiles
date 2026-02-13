return {
  "olimorris/codecompanion.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
  opts = {
    interactions = {
      chat = { adapter = "openai" },
      inline = { adapter = "openai" },
      cmd = { adapter = "openai" },
    },
  },
}
