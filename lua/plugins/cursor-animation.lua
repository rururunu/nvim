return {
  {
    "nvim-mini/mini.animate",
    enabled = false,
  },
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      stiffness = 0.8,
      trailing_stiffness = 0.8,
      matrix_pixel_threshold = 0.5,
      damping = 0.95,
      distance_stop_animating = 0.5,
      time_interval = 17,
      smear_between_buffers = false,
      smear_insert_mode = false,
      smear_terminal_mode = false,
      smear_to_cmd = false,
      particles_enabled = false,
    },
    config = function(_, opts)
      local cursor = require("smear_cursor")
      cursor.setup(opts)
      local wanted = true
      local function update()
        local enabled = wanted and vim.bo.buftype == "" and vim.bo.filetype ~= "neominimap"
        if cursor.enabled ~= enabled then
          cursor.enabled = enabled
        end
      end
      vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
        group = vim.api.nvim_create_augroup("smooth_cursor_scope", { clear = true }),
        callback = update,
      })
      vim.keymap.set("n", "<leader>uA", function()
        wanted = not wanted
        update()
        vim.notify(wanted and "平滑光标已开启" or "平滑光标已关闭")
      end, { desc = "开关平滑光标" })
      update()
    end,
  },
}
