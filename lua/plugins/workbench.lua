return {
  {
    "stevearc/overseer.nvim",
    cmd = { "OverseerRun", "OverseerToggle", "OverseerOpen", "OverseerShell" },
    opts = {
      task_list = { direction = "bottom", min_height = 8, max_height = 0.3 },
      form = { border = "rounded" },
      task_win = { border = "rounded" },
    },
  },
  { "folke/which-key.nvim", opts = { spec = { { "<leader>r", group = "运行 / 测试" } } } },
}
