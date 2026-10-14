local M = {}

function M.open()
  if vim.bo.filetype ~= "markdown" or vim.bo.buftype ~= "" then return end
  require("lazy").load({ plugins = { "markdown-preview.nvim", "render-markdown.nvim" } })
  -- 编辑器保留源码；网页负责完整的 Markdown / HTML 渲染。
  require("render-markdown").buf_disable()
  vim.wo.conceallevel = 0
  if #vim.api.nvim_list_uis() > 0 then vim.cmd("MarkdownPreview") end
end

function M.setup()
  vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
    group = vim.api.nvim_create_augroup("markdown_browser", { clear = true }),
    callback = function(args)
      if vim.bo[args.buf].filetype ~= "markdown" or vim.bo[args.buf].buftype ~= "" then return end
      local buf = args.buf
      vim.schedule(function()
        if vim.api.nvim_get_current_buf() == buf then M.open() end
      end)
    end,
  })
  -- 保留先前命令作为兼容入口。
  vim.api.nvim_create_user_command("MarkdownSplit", M.open, { desc = "打开浏览器 Markdown 完整预览" })
  vim.api.nvim_create_user_command("MarkdownSplitClose", function()
    if vim.fn.exists(":MarkdownPreviewStop") == 2 then vim.cmd("MarkdownPreviewStop") end
  end, { desc = "停止浏览器 Markdown 预览" })
  vim.schedule(M.open)
end

return M
