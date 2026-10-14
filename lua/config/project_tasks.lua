local M = { last = {} }
local function exists(root, file)
  return vim.fn.filereadable(root .. "/" .. file) == 1
end
function M.root()
  return vim.t.workspace_path or vim.fn.getcwd()
end
local function executable(name)
  local path = vim.fn.exepath(name)
  return path ~= "" and path or name
end
local function wrapper(root, win, unix, fallback)
  local name = vim.fn.has("win32") == 1 and win or unix
  return exists(root, name) and root .. "/" .. name or executable(fallback)
end

function M.detect(root, file)
  root, file = root or M.root(), file or vim.api.nvim_buf_get_name(0)
  local choices = {}
  local signal = require("config.signal_project")
  if signal.matches(root) then
    return signal.tasks(root)
  end
  local function add(label, cmd, args)
    choices[#choices + 1] = { name = label, cmd = cmd, args = args, cwd = root }
  end
  if exists(root, "Cargo.toml") then
    add("运行项目 · Cargo", executable("cargo"), { "run", "--color=never" })
    add("构建项目 · Cargo", executable("cargo"), { "build", "--color=never", "--message-format=short" })
    add("检查项目 · Cargo", executable("cargo"), { "check", "--color=never", "--message-format=short" })
    add("测试全部 · Cargo", executable("cargo"), { "test", "--color=never", "--message-format=short" })
  elseif exists(root, "pom.xml") then
    local mvn = wrapper(root, "mvnw.cmd", "mvnw", "mvn")
    add("构建项目 · Maven", mvn, { "-B", "-Dstyle.color=never", "-DskipTests", "package" })
    add("测试全部 · Maven", mvn, { "-B", "-Dstyle.color=never", "test" })
    -- 启动方式取决于项目，不预设每个 Java 项目都是 Spring Boot。
  elseif exists(root, "build.gradle") or exists(root, "build.gradle.kts") then
    local gradle = wrapper(root, "gradlew.bat", "gradlew", "gradle")
    add("构建项目 · Gradle", gradle, { "--console=plain", "build", "-x", "test" })
    add("测试全部 · Gradle", gradle, { "--console=plain", "test" })
  end
  if exists(root, "package.json") then
    local ok, pkg = pcall(vim.json.decode, table.concat(vim.fn.readfile(root .. "/package.json"), "\n"))
    local manager = exists(root, "pnpm-lock.yaml") and "pnpm" or (exists(root, "yarn.lock") and "yarn" or "npm")
    for _, script in ipairs({ "dev", "start", "build", "test", "check", "lint" }) do
      if ok and type(pkg.scripts) == "table" and pkg.scripts[script] then
        add("项目脚本 · " .. script, executable(manager), { "run", script })
      end
    end
  end
  if file:match("%.java$") then
    add("运行当前 Java 文件（源码启动）", executable("java"), { file })
  end
  if file:match("%.py$") then
    add("运行当前 Python 文件", executable("python"), { file })
  end
  if exists(root, ".vscode/tasks.json") then
    choices[#choices + 1] = { name = "选择 VS Code / 更多任务模板", template = true }
  end
  return choices
end

M.errorformat = table.concat({
  "%E[ERROR] %f:[%l\\,%c] %m",
  "%E[ERROR] %f:[%l] %m",
  "%Ee: file:///%f:%l:%c %m",
  "%Ee: %f: (%l\\, %c): %m",
  "%E%f:%l:%c: error: %m",
  "%W%f:%l:%c: warning: %m",
  "%E%f:%l: error: %m",
  "%E%f:%l:%c: %m",
  "%E%f:%l: %m",
  "%-G%.%#",
}, ",")

function M.run(def, opts)
  opts = opts or {}
  if def.signal_setup then
    require("config.signal_project").setup_project()
    return
  end
  if def.signal_start then
    return require("config.signal_project").launch(def.cwd, def.debug)
  end
  if def.template then
    require("overseer").run_task({ cwd = M.root() })
    return
  end
  local program = def.cmd
  if type(program) ~= "string" or vim.fn.executable(program) ~= 1 then
    vim.notify(
      "缺少运行工具：" .. tostring(program) .. "，请先安装或使用项目 wrapper",
      vim.log.levels.ERROR
    )
    return
  end
  if opts.save ~= false then
    local ok, err = pcall(vim.cmd, "wall")
    if not ok then
      vim.notify("保存失败，任务未启动：" .. tostring(err), vim.log.levels.ERROR)
      return
    end
  end
  local overseer = require("overseer")
  for _, task in ipairs(overseer.list_tasks({})) do
    if task.cwd == def.cwd and task.name == def.name and task:is_running() then
      vim.notify("同一任务正在运行，可先停止或选择重新运行", vim.log.levels.WARN)
      return task
    end
  end
  -- 数组直接启动进程，避免继承 PowerShell 与 cmd 的不兼容 shell 参数。
  local command = { def.cmd }
  local args = def.args
  if vim.fn.has("win32") == 1 and (def.cmd:lower():match("%.bat$") or def.cmd:lower():match("%.cmd$")) then
    local shell = vim.o.shell:lower()
    local quoted = { vim.fn.shellescape(def.cmd) }
    for _, arg in ipairs(def.args or {}) do
      quoted[#quoted + 1] = vim.fn.shellescape(arg)
    end
    command = (shell:find("powershell", 1, true) or shell:find("pwsh", 1, true)) and "& " or "call "
    command = command .. table.concat(quoted, " ")
    args = nil
  end
  local task = overseer.new_task({
    name = def.name,
    cmd = command,
    args = args,
    cwd = def.cwd,
    env = def.env,
    strategy = { "jobstart", use_terminal = false },
    components = {
      "on_exit_set_status",
      {
        "on_output_quickfix",
        errorformat = M.errorformat,
        open_on_exit = "failure",
        items_only = true,
        tail = false,
      },
      "on_complete_notify",
    },
  })
  if task:start() == false then
    vim.notify("任务启动失败，请查看 :OverseerOpen 与 :DevHealth", vim.log.levels.ERROR)
    task:dispose(true)
    return
  end
  M.last[def.cwd] = { def = vim.deepcopy(def), task = task }
  if opts.open ~= false then
    overseer.open({ direction = "bottom", enter = false })
  end
  return task
end

function M.pick()
  local choices = M.detect()
  choices[#choices + 1] = { name = "选择更多任务模板（含 VS Code tasks）", template = true }
  vim.ui.select(choices, {
    prompt = "运行 / 构建 / 测试（启动前保存文件）",
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if choice then
      M.run(choice)
    end
  end)
end

function M.rerun()
  local last = M.last[M.root()]
  if not last then
    M.pick()
    return
  end
  if last.task:is_running() then
    last.task:stop()
  end
  vim.schedule(function()
    M.run(last.def)
  end)
end

function M.stop()
  local running = vim.tbl_filter(function(t)
    return t.cwd == M.root() and t:is_running()
  end, require("overseer").list_tasks({}))
  if #running == 0 then
    vim.notify("当前项目没有运行中的任务")
    return
  end
  vim.ui.select(running, {
    prompt = "停止任务",
    format_item = function(t)
      return t.name
    end,
  }, function(t)
    if t then
      t:stop()
    end
  end)
end

function M.test(scope)
  local ft = vim.bo.filetype
  if ft == "java" then
    require("jdtls")[scope == "file" and "test_class" or "test_nearest_method"]()
  elseif ft == "rust" then
    vim.cmd("RustLsp testables")
  elseif ft == "kotlin" and (exists(M.root(), "build.gradle") or exists(M.root(), "build.gradle.kts")) then
    local package = ""
    local class
    for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
      package = line:match("^%s*package%s+([%w_.]+)") or package
      class = class or line:match("class%s+([%w_]+)")
    end
    local default = (package ~= "" and package .. "." or "") .. (class or vim.fn.expand("%:t:r"))
    vim.ui.input(
      { prompt = "Gradle 测试筛选（可用 Class.method 或通配符）：", default = default },
      function(pattern)
        if pattern and pattern ~= "" then
          M.run({
            name = "Gradle 测试 · " .. pattern,
            cwd = M.root(),
            cmd = wrapper(M.root(), "gradlew.bat", "gradlew", "gradle"),
            args = { "--console=plain", "test", "--tests", pattern },
          })
        end
      end
    )
  else
    vim.notify(
      "当前 / 文件级测试支持 Java 与 Rust；Kotlin 请运行 Gradle 测试任务",
      vim.log.levels.INFO
    )
  end
end

function M.failed_tests()
  local failed = vim.tbl_filter(function(task)
    return task.cwd == M.root()
      and task.status == "FAILURE"
      and (task.name:lower():find("test", 1, true) or task.name:find("测试", 1, true))
  end, require("overseer").list_tasks({}))
  if #failed == 0 then
    vim.notify("当前项目没有失败的测试任务记录")
    return
  end
  vim.ui.select(failed, {
    prompt = "重跑失败测试任务（整个任务）",
    format_item = function(task)
      return task.name
    end,
  }, function(task)
    if task then
      local ok, err = pcall(vim.cmd, "wall")
      if not ok then
        vim.notify(tostring(err), vim.log.levels.ERROR)
        return
      end
      task:restart()
    end
  end)
end

return M
