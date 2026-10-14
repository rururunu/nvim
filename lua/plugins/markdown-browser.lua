return {
  "iamcco/markdown-preview.nvim",
  ft = { "markdown" },
  init = function()
    vim.g.mkdp_auto_start = 0 -- 浏览器只作为手动预览入口。
    vim.g.mkdp_auto_close = 0
    vim.g.mkdp_refresh_slow = 0
    vim.g.mkdp_combine_preview = 1
    vim.g.mkdp_combine_preview_auto_refresh = 1
    vim.g.mkdp_page_title = "${name} · Markdown 预览"
    vim.g.mkdp_open_to_the_world = 0
  end,
}
