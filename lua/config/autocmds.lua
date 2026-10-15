-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- 删除 LazyVim 自动启用拼写检查的 autocmd
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- 禁用注释自动延续（在 FileType 事件触发，确保覆盖插件设置）

require("config.recent_projects").setup()
require("config.project_theme").setup()
require("config.island_ui").setup()
require("config.editor_card").setup()
require("config.markdown_split").setup()
require("config.workspace").setup()
require("config.workbench").setup()
require("config.buffers").setup()

vim.api.nvim_create_user_command("Dashboard", function()
  Snacks.dashboard()
end, { desc = "打开中文启动页" })

vim.api.nvim_create_user_command("Exit", function()
  require("config.exit").pick()
end, { desc = "选择保存全部或放弃修改后退出 Neovim" })
