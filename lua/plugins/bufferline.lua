return {
  "akinsho/bufferline.nvim",
  enabled = false,
  init = function()
    vim.opt.showtabline = 0
    for key, command in pairs({ ["<S-h>"] = "bprevious", ["<S-l>"] = "bnext", ["[b"] = "bprevious", ["]b"] = "bnext" }) do
      vim.keymap.set(
        "n",
        key,
        "<cmd>" .. command .. "<cr>",
        { desc = command == "bnext" and "下一个缓冲区" or "上一个缓冲区" }
      )
    end
  end,
}
