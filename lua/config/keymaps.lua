-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set({ "n", "i" }, "<C-s>", "<cmd>write<cr>", { desc = "保存当前文件" })
vim.keymap.set("n", "<leader>bd", function() require("config.buffers").close() end, { desc = "关闭当前文件" })
vim.keymap.set("n", "<C-p>", function()
  Snacks.picker.files({ cwd = require("config.project_tasks").root() })
end, { desc = "查找项目文件" })
vim.keymap.set("n", "<leader>/", function()
  Snacks.picker.grep({ cwd = require("config.project_tasks").root() })
end, { desc = "搜索项目内容" })
vim.keymap.set("n", "<F12>", vim.lsp.buf.definition, { desc = "跳转到定义" })
vim.keymap.set("n", "<S-F12>", vim.lsp.buf.references, { desc = "查找引用" })
vim.keymap.set("n", "<F2>", function()
  return ":IncRename " .. vim.fn.expand("<cword>")
end, { expr = true, desc = "重命名符号（预览）" })
vim.keymap.set("n", "<A-Left>", "<C-o>", { desc = "返回上个位置" })
vim.keymap.set("n", "<A-Right>", "<C-i>", { desc = "前进到下个位置" })
vim.keymap.set("n", "<leader>rd", function()
  local signal = require("config.signal_project")
  if signal.matches(require("config.project_tasks").root()) then
    signal.debug()
  else
    require("dap").continue()
  end
end, { desc = "附加 Signal 调试 / 启动调试" })

vim.keymap.set("n", "<leader>qs", function()
  require("config.workspace").restore()
end, { desc = "恢复当前项目工作区" })
vim.keymap.set("n", "<leader>qS", function()
  require("config.workspace").save()
  vim.notify("工作区已保存")
end, { desc = "保存当前项目工作区" })

vim.keymap.set("n", "<leader><leader>", function()
  require("config.workbench").menu()
end, { desc = "中文开发工作台" })
vim.keymap.set("n", "<F1>", function()
  require("config.workbench").menu()
end, { desc = "中文开发工作台" })
vim.keymap.set("n", "<leader>rf", function()
  require("config.project_tasks").failed_tests()
end, { desc = "重跑失败的测试任务" })
vim.keymap.set("n", "<F5>", function()
  require("dap").continue()
end, { desc = "调试：启动 / 继续" })
vim.keymap.set("n", "<F9>", function()
  require("dap").toggle_breakpoint()
end, { desc = "切换断点" })
vim.keymap.set("n", "<leader>rr", function()
  require("config.project_tasks").pick()
end, { desc = "运行 / 构建 / 测试" })
vim.keymap.set("n", "<leader>rl", function()
  require("config.project_tasks").rerun()
end, { desc = "重新运行上次任务" })
vim.keymap.set("n", "<leader>rs", function()
  require("config.project_tasks").stop()
end, { desc = "停止项目任务" })
vim.keymap.set("n", "<leader>ro", function()
  require("overseer").toggle()
end, { desc = "任务列表与输出" })
vim.keymap.set("n", "<leader>re", "<cmd>copen<cr>", { desc = "构建错误列表" })
vim.keymap.set("n", "<leader>rt", function()
  require("config.project_tasks").test("nearest")
end, { desc = "运行当前测试 / 选择 Rust 测试" })
vim.keymap.set("n", "<leader>rT", function()
  require("config.project_tasks").test("file")
end, { desc = "运行当前测试类 / 选择 Rust 测试" })

vim.keymap.set("n", "<leader>gg", function()
  Snacks.lazygit({
    cwd = vim.fn.getcwd(),
    override = false,
    win = {
      position = "float",
      relative = "editor",
      width = 0.95,
      height = 0.9,
      row = 0.05,
      col = 0.025,
      border = "rounded",
      title = " LazyGit ",
    },
  })
end, { desc = "LazyGit（当前项目）" })

for key, direction in pairs({ Left = "h", Down = "j", Up = "k", Right = "l" }) do
  local move = function()
    require("config.window_navigation").move(direction)
  end
  vim.keymap.set({ "n", "t" }, "<C-" .. direction .. ">", move, { desc = "切换到相邻区域" })
end

for key, command in pairs({
  Up = "resize +2",
  Down = "resize -2",
  Left = "vertical resize -2",
  Right = "vertical resize +2",
}) do
  vim.keymap.set({ "n", "t" }, "<C-" .. key .. ">", function()
    require("config.window_navigation").resize(command)
  end, { desc = "调整窗口大小" })
end

vim.keymap.set("x", "<C-c>", '"+y', { desc = "复制到 Windows 剪贴板" })
vim.keymap.set("i", "<C-v>", "<C-r><C-p>+", { desc = "粘贴 Windows 剪贴板" })

-- 快速按两次 p 相当于 Esc（插入模式和可视模式）
vim.keymap.set({ "i", "v" }, "pp", "<Esc>", { noremap = true, silent = true, desc = "Fast pp to Esc" })

-- 普通模式和命令模式下按 \ 保存文件
vim.keymap.set({ "n", "c" }, "\\", "<cmd>w<cr>", { noremap = true, silent = true, desc = "Save file" })

-- 随时从最近项目中切换工作目录。
vim.keymap.set("n", "<leader>fp", function()
  require("config.recent_projects").open_picker()
end, { desc = "选择项目" })

vim.keymap.set("n", "<leader>uP", function()
  require("config.project_theme").pick()
end, { desc = "选择当前项目主题" })
