return {
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewToggleFiles",
    },
    keys = {
      {
        "<leader>gr",
        "<cmd>DiffviewOpen HEAD<cr>",
        desc = "Review changes",
      },
      {
        "<leader>gR",
        function()
          vim.ui.input({
            prompt = "Review changes since: ",
            default = "origin/main",
          }, function(base)
            if base and base ~= "" then
              vim.cmd("DiffviewOpen " .. base)
            end
          end)
        end,
        desc = "Review changes since…",
      },
      { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Commit history (diffview)" },
      { "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "Close diffview" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = { merge_tool = { layout = "diff3_mixed" } },
    },
  },
}
