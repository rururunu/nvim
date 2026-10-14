local M = {}

function M.open(path)
  local stat = path and vim.uv.fs_stat(path)
  if not stat then
    vim.notify("文件或目录不存在", vim.log.levels.WARN)
    return
  end
  local native = vim.fs.normalize(path):gsub("/", "\\")
  local args = { "explorer.exe", stat.type == "directory" and native or ("/select," .. native) }
  local ok, err = pcall(vim.system, args, { detach = true })
  if not ok then vim.notify("打开资源管理器失败：" .. tostring(err), vim.log.levels.ERROR) end
end

function M.selected(picker)
  local item = picker:current()
  return item and item.file or picker:cwd()
end

function M.context(picker)
  local mouse = vim.fn.getmousepos()
  if mouse.winid == picker.list.win.win and mouse.line > 0 then
    picker.list:move(picker.list:row2idx(mouse.line), true, true)
  end
  M.path = M.selected(picker)
  vim.cmd([[nnoremenu <silent> ExplorerContext.在\ Windows\ 资源管理器中显示 <Cmd>lua require('config.windows_explorer').open(require('config.windows_explorer').path)<CR>]])
  vim.cmd("popup ExplorerContext")
end

return M
