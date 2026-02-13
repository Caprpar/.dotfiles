return {
  -- Treesitter parser för syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "graphql",
      })
    end,
  },

  -- LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        graphql = {},
      },
    },
  },

  -- Formatering med Prettier
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        graphql = { "prettier" },
      },
    },
  },
}
