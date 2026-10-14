-- 只检查实际仓库的任务参数；不会启动 Signal 业务服务。
vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
require("persistence").stop()
require("config.recent_projects").record = function() end
local root = "C:/My/code/gitea/temporary/Signal-Server"
local profile = require("config.signal_project")
assert(profile.matches(root))
assert(not profile.matches(vim.fn.tempname()))
local choices = require("config.project_tasks").detect(root, "")
assert(#choices == 7)
assert(choices[1].env.JAVA_HOME:find("/26/", 1, true))
assert(choices[1].args[4] == "service")
assert(choices[3].args[6] == "-Dtest=UtilTest")
local tasks = require("config.project_tasks")
local original, captured = tasks.run
tasks.run = function(def)
  captured = def
  return def
end
profile.launch(root, true)
tasks.run = original
assert(captured, "launch definition generated")
assert(captured.cmd:find("/26/", 1, true))
local debug, config, secrets = false, false, false
for _, arg in ipairs(captured.args) do
  if arg:find("address=127.0.0.1:5005", 1, true) then
    debug = true
  end
  if arg == profile.settings(root).config then
    config = true
  end
  if arg:find("-Dsecrets.bundle.filename=", 1, true) == 1 then
    secrets = true
  end
end
assert(debug and config and secrets)
print("SIGNAL_TASK_AND_DEBUG_PROFILE_OK")
vim.cmd("qa!")
