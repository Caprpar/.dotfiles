return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          settings = {
            typescript = {
              inlayHints = {
                functionLikeReturnTypes = { enabled = false },
              },
            },
            javascript = {
              inlayHints = {
                functionLikeReturnTypes = { enabled = false },
              },
            },
          },
        },
      },
    },
  },
}
-- ```
--
-- Or if you just want a quick toggle without changing config, run this in nvim:
-- ```
-- :lua vim.lsp.inlay_hint.enable(false)
