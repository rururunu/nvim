local M = {}

function M.execute(choice)
  if choice == "save" then
    local ok, err = pcall(vim.cmd, "wqa")
    if not ok then
      vim.notify("保存失败，已保留编辑窗口：\n" .. tostring(err), vim.log.levels.ERROR)
    end
    return ok
  elseif choice == "discard" then
    local autowrite, autowriteall = vim.o.autowrite, vim.o.autowriteall
    vim.o.autowrite = false
    vim.o.autowriteall = false
    local ok, err = pcall(vim.cmd, "qa!")
    if not ok then
      vim.o.autowrite, vim.o.autowriteall = autowrite, autowriteall
      vim.notify("退出失败：" .. tostring(err), vim.log.levels.ERROR)
    end
    return ok
  end
end

function M.pick()
  return Snacks.picker.select({
    { action = "save", label = "保存所有文件并退出" },
    { action = "discard", label = "不保存所有文件并退出（丢弃未保存修改）" },
  }, {
    prompt = "退出 Neovim（Enter确认 / Esc取消）",
    format_item = function(item)
      return item.label
    end,
    snacks = {
      win = { input = { keys = { ["<Esc>"] = { "close", mode = { "n", "i" } } } } },
    },
  }, function(choice)
    if choice then
      M.execute(choice.action)
    end
  end)
end

return M
