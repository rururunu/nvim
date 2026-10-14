vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
require("persistence").stop()
require("config.recent_projects").record = function() end
local root = "C:/My/code/gitea/temporary/Signal-Server"
local profiles = require("config.signal_project")
assert(profiles.matches(root), "Signal project identification")
local choices = require("config.project_tasks").detect(root, "")
assert(#choices == 7 and choices[1].env.JAVA_HOME:find("/26/", 1, true), "JDK 26 profile")
assert(choices[3].args[6] == "-Dtest=UtilTest", "targeted test")
local logs = vim.fn.stdpath("cache") .. "/signal-workbench-validation"
vim.fn.mkdir(logs, "p")
for _, idx in ipairs({ 1, 3 }) do
  local def = choices[idx]
  local task = assert(require("config.project_tasks").run(def, { save = false, open = false }))
  assert(
    vim.wait(55000, function()
      return task:is_complete()
    end, 100),
    "Signal task timeout"
  )
  local output = vim.api.nvim_buf_get_lines(task:get_bufnr(), 0, -1, false)
  vim.fn.writefile(output, logs .. "/" .. (idx == 1 and "compile" or "UtilTest") .. ".log")
  print(def.name .. " " .. task.status)
  assert(task.status == "SUCCESS", table.concat(vim.list_slice(output, math.max(1, #output - 12)), "\n"))
end
print("SIGNAL_PROFILE_CHECK_FINISHED")
vim.cmd("qa!")
