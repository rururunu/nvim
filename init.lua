-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- 切项目和退出不会隐式保存，保存由用户或明确的构建操作触发。
vim.opt.autowriteall = false
vim.opt.autowrite = false
