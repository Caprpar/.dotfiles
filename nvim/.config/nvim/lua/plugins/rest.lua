-- Rebind rest.nvim (kulala) keys from <leader>R to <leader>r
return {
  "mistweaverco/kulala.nvim",
  keys = {
    -- disable the default uppercase bindings
    { "<leader>R", false },
    { "<leader>Rb", false },
    { "<leader>Rc", false },
    { "<leader>RC", false },
    { "<leader>Re", false },
    { "<leader>Rg", false },
    { "<leader>Ri", false },
    { "<leader>Rn", false },
    { "<leader>Rp", false },
    { "<leader>Rq", false },
    { "<leader>Rr", false },
    { "<leader>Rs", false },
    { "<leader>RS", false },
    { "<leader>Rt", false },

    -- lowercase replacements
    { "<leader>r", "", desc = "+Rest" },
    { "<leader>rb", "<cmd>lua require('kulala').scratchpad()<cr>", desc = "Open scratchpad" },
    { "<leader>rc", "<cmd>lua require('kulala').copy()<cr>", desc = "Copy as cURL", ft = "http" },
    { "<leader>rC", "<cmd>lua require('kulala').from_curl()<cr>", desc = "Paste from curl", ft = "http" },
    { "<leader>re", "<cmd>lua require('kulala').set_selected_env()<cr>", desc = "Set environment", ft = "http" },
    {
      "<leader>rg",
      "<cmd>lua require('kulala').download_graphql_schema()<cr>",
      desc = "Download GraphQL schema",
      ft = "http",
    },
    { "<leader>ri", "<cmd>lua require('kulala').inspect()<cr>", desc = "Inspect current request", ft = "http" },
    { "<leader>rn", "<cmd>lua require('kulala').jump_next()<cr>", desc = "Jump to next request", ft = "http" },
    { "<leader>rp", "<cmd>lua require('kulala').jump_prev()<cr>", desc = "Jump to previous request", ft = "http" },
    { "<leader>rq", "<cmd>lua require('kulala').close()<cr>", desc = "Close window", ft = "http" },
    { "<leader>rr", "<cmd>lua require('kulala').replay()<cr>", desc = "Replay the last request" },
    { "<leader>rs", "<cmd>lua require('kulala').run()<cr>", desc = "Send the request", ft = "http" },
    { "<leader>rS", "<cmd>lua require('kulala').show_stats()<cr>", desc = "Show stats", ft = "http" },
    { "<leader>rt", "<cmd>lua require('kulala').toggle_view()<cr>", desc = "Toggle headers/body", ft = "http" },
  },
}
