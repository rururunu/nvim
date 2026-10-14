vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
require("persistence").stop()
require("config.recent_projects").record = function() end -- 验证样例不进入最近项目历史。
local temp = vim.fn.tempname() .. "-backup-test"
vim.fn.mkdir(temp .. "/config/lua", "p")
vim.fn.writefile({ "old" }, temp .. "/config/init.lua")
vim.fn.writefile({ "old module" }, temp .. "/config/lua/a.lua")
local real = vim.fn.stdpath
vim.fn.stdpath = function(kind)
  if kind == "config" then
    return temp .. "/config"
  elseif kind == "state" then
    return temp .. "/state"
  else
    return real(kind)
  end
end
local work = require("config.workbench")
local backup = work.backup()
vim.fn.writefile({ "new" }, temp .. "/config/init.lua")
vim.fn.writefile({ "added" }, temp .. "/config/lua/new.lua")
local select = vim.ui.select
vim.ui.select = function(items, opts, cb)
  if opts.prompt:find("选择要恢复", 1, true) then
    cb(backup)
  else
    cb(items[2])
  end
end
work.restore()
assert(vim.fn.readfile(temp .. "/config/init.lua")[1] == "old", "restore contents")
assert(vim.fn.filereadable(temp .. "/config/lua/new.lua") == 0, "remove newer modules")
assert(#vim.fn.glob(temp .. "/state/config-backups/*", false, true) == 2, "recovery backup distinct")
vim.ui.select = select
vim.fn.stdpath = real
print("CONFIG_BACKUP_RESTORE_OK")
vim.cmd("qa!")

