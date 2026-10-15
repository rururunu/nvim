return {
  "Isrothy/neominimap.nvim",
  lazy = false,
  keys = {
    { "<leader>um", "<cmd>Neominimap Toggle<cr>", desc = "显示/隐藏代码缩略图" },
    { "<leader>uM", "<cmd>Neominimap ToggleFocus<cr>", desc = "进入/离开代码缩略图" },
  },
  init = function()
    vim.g.neominimap = {
      auto_enable = true,
      layout = "float",
      delay = 200,
      exclude_filetypes = {
        "help",
        "bigfile",
        "snacks_dashboard",
        "markdown_preview",
        "editor_card_bar",
        "editor_card_edge",
      },
      exclude_buftypes = { "nofile", "nowrite", "quickfix", "terminal", "prompt" },
      buf_filter = function(buf)
        return not vim.b[buf].markdown_preview
          and vim.api.nvim_buf_get_name(buf) ~= ""
          and vim.api.nvim_buf_line_count(buf) < 20000
      end,
      win_filter = function(win)
        return vim.api.nvim_win_get_config(win).relative == "" and vim.api.nvim_win_get_width(win) >= 100
      end,
      float = {
        minimap_width = 16,
        margin = { right = 1, top = 0, bottom = 0 },
        window_border = "none",
        z_index = 3,
      },
      click = { enabled = true, auto_switch_focus = false },
      search = { enabled = true },
      diagnostic = { enabled = true },
      git = { enabled = true },
    }
    vim.opt.sidescrolloff = 18
  end,
}
