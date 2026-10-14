-- 日常编辑使用原生窗口，保留旧接口供终端、预览与项目切换调用。
-- 原生窗口管理关闭保护、分屏、缓冲区和会话，不再创建占位缓冲区。
local M = { cards = {} }
function M.clear() end
function M.refresh() end
function M.setup() end
return M
