-- ~/.config/nvim/lua/plugins/omp.lua
return {
  {
    "rauls-kjarners/omp.nvim",
    event = "VeryLazy",
    config = function()
      require("omp").setup()
    end,
  },
}
