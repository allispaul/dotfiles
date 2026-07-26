return {
  {
    "mfussenegger/nvim-lint",
    event = "LazyFile",
    opts = {
      -- Map your linters to file types
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        bash = { "shellcheck" },
      },
    },
  },
}
