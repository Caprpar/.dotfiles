return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        cssls = {
          -- detta räcker oftast, LazyVim hittar cmd själv om paketet finns globalt
          -- cmd = { "vscode-css-language-server", "--stdio" },
        },
      },
    },
  },
}
