local api = vim.api
vim.o.columns = 160
vim.o.lines = 45
api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
require("lazy").load({ plugins = { "overseer.nvim" } })
require("persistence").stop()
require("config.recent_projects").record = function() end -- 验证样例不进入最近项目历史。
local root = vim.fn.tempname() .. "-workbench"
vim.fn.mkdir(root, "p")
local function write(name, lines)
  vim.fn.mkdir(vim.fs.dirname(root .. "/" .. name), "p")
  vim.fn.writefile(lines, root .. "/" .. name)
end
write("one.txt", { "one" })
write("two.txt", { "two" })
vim.cmd("edit " .. vim.fn.fnameescape(root .. "/one.txt"))
api.nvim_buf_set_lines(0, 0, 1, false, { "unsaved" })
local source = api.nvim_get_current_buf()
vim.cmd("vsplit " .. vim.fn.fnameescape(root .. "/two.txt"))
assert(api.nvim_win_get_config(0).relative == "", "native editor")
vim.t.workspace_path = root
vim.cmd("tcd " .. vim.fn.fnameescape(root))
assert(require("config.workspace").save(), "session save")
assert(require("config.workspace").restore(), "session restore")
assert(vim.bo[source].modified, "unsaved buffer retained")
assert(#api.nvim_tabpage_list_wins(0) == 2, "two file windows restored")
local tasks = require("config.project_tasks")
local java = "C:/My/data/Jir/home/21/temurin/bin"
write("Main.java", {
  'public class Main { public static void main(String[] args) { if (2+2!=4) throw new AssertionError(); System.out.println("JAVA_OK"); } }',
})
local function run(def)
  local task = assert(tasks.run(def, { save = false, open = false }))
  assert(
    vim.wait(45000, function()
      return task:is_complete()
    end, 50),
    "task timed out: " .. def.name
  )
  return task
end
local task = run({ name = "Java source run", cmd = java .. "/java.exe", args = { root .. "/Main.java" }, cwd = root })
assert(
  task.status == "SUCCESS",
  task.status .. " " .. table.concat(api.nvim_buf_get_lines(task:get_bufnr(), 0, -1, false), "\n")
)
write("Bad.java", { "class Bad {", "  void x() { missing(); }", "}" })
task = run({ name = "Java compile failure", cmd = java .. "/javac.exe", args = { root .. "/Bad.java" }, cwd = root })
assert(task.status == "FAILURE", "compiler must fail")
vim.wait(100)
local qf = vim.fn.getqflist()
assert(#qf > 0 and qf[1].lnum == 2, "compiler error line")
vim.cmd("cc 1")
assert(api.nvim_buf_get_name(0):match("Bad.java$"), "quickfix file jump")
vim.cmd("cclose")
local node = vim.fn.exepath("node")
local long = assert(
  tasks.run(
    { name = "cancel test", cmd = node, args = { "-e", "setInterval(()=>{},1000)" }, cwd = root },
    { save = false, open = false }
  )
)
assert(
  vim.wait(2000, function()
    return long:is_running()
  end, 20),
  "task started"
)
long:stop()
assert(
  vim.wait(3000, function()
    return long:is_complete()
  end, 20),
  "task stopped"
)
assert(long.status == "CANCELED", "cancel status")
local quick = run({ name = "rerun test", cmd = node, args = { "-e", "console.log('repeat')" }, cwd = root })
vim.t.workspace_path = root
tasks.rerun()
assert(
  vim.wait(10000, function()
    local last = tasks.last[root]
    return last and last.task ~= quick and last.task:is_complete()
  end, 50),
  "rerun completes"
)
assert(tasks.last[root].task.status == "SUCCESS", "rerun success")
local wrapperRoot = root .. "/space 中文"
vim.fn.mkdir(wrapperRoot, "p")
vim.fn.writefile({ "@echo off", "echo WRAPPER_OK", "exit /b 0" }, wrapperRoot .. "/check.cmd")
local wrapped = run({ name = "Windows wrapper", cmd = wrapperRoot .. "/check.cmd", args = {}, cwd = wrapperRoot })
assert(wrapped.status == "SUCCESS", "wrapper path with spaces")
print("WORKSPACE_TASK_SUCCESS_FAILURE_CANCEL_OK")
vim.o.autowrite = false
vim.o.autowriteall = false
vim.cmd("qa!")

