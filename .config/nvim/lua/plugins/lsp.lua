return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = {
            "/usr/bin/clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
        },
        pylsp = {
          settings = {
            pylsp = {
              plugins = {
                pycodestyle = { enabled = false },
              },
            },
          },
        },
      },
    },
  },
}
