return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  opts = {
    ensure_installed = { "lua", "javascript", "typescript", "html", "css", "python", "yaml", "sql" }, -- välj språk
    highlight = { enable = true },
  },
}
