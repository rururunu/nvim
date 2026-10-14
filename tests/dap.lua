local api = vim.api
api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
require("persistence").stop()
require("config.recent_projects").record = function() end -- 验证样例不进入最近项目历史。
local root = vim.fn.stdpath("cache") .. "/workbench-validation"
local dap = require("dap")
-- 自动打开 DAP UI 会改变窗口焦点，测试只检查协议事件。
dap.listeners.after.event_initialized.dapui_config = nil
dap.listeners.before.event_terminated.dapui_config = nil
dap.listeners.before.event_exited.dapui_config = nil
local javaRoot = root .. "/java"
vim.cmd("tcd " .. vim.fn.fnameescape(javaRoot))
vim.cmd("edit " .. vim.fn.fnameescape(javaRoot .. "/src/main/java/sample/Main.java"))
local client
assert(
  vim.wait(55000, function()
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      if c.name == "jdtls" and c.initialized then
        client = c
        return true
      end
    end
  end, 100),
  "Java LSP"
)
require("jdtls.dap").setup_dap({ hotcodereplace = "auto" })
local function debug(config, name)
  local stopped, terminated = false, false
  dap.listeners.after.event_stopped.workbench_test = function()
    stopped = true
  end
  dap.listeners.after.event_terminated.workbench_test = function()
    terminated = true
  end
  dap.run(config)
  assert(
    vim.wait(35000, function()
      return stopped
    end, 100),
    name .. " breakpoint timeout"
  )
  local session = assert(dap.session())
  assert(
    vim.wait(10000, function()
      return session.current_frame ~= nil
    end, 50),
    "stack frame at breakpoint"
  )
  dap.continue()
  assert(
    vim.wait(15000, function()
      return terminated or dap.session() == nil
    end, 100),
    name .. " termination timeout"
  )
  print(name .. "_BREAKPOINT_CONTINUE_OK")
end
debug({
  type = "java",
  request = "launch",
  name = "Java validation",
  mainClass = "sample.Main",
  classPaths = { javaRoot .. "/target/classes" },
  cwd = javaRoot,
  stopOnEntry = true,
  console = "internalConsole",
}, "JAVA_DAP")
vim.cmd("edit " .. vim.fn.fnameescape(root .. "/rust/src/main.rs"))
require("lazy").load({ plugins = { "rustaceanvim" } })
local extension = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension"
dap.adapters.workbench_lldb = require("rustaceanvim.config").get_codelldb_adapter(
  extension .. "/adapter/codelldb.exe",
  extension .. "/lldb/bin/liblldb.dll"
)
debug({
  type = "workbench_lldb",
  request = "launch",
  name = "Rust validation",
  program = root .. "/rust/target/debug/workbench_validation.exe",
  cwd = root .. "/rust",
  stopOnEntry = true,
}, "RUST_DAP")
local kroot = root .. "/kotlin"
vim.fn.mkdir(kroot .. "/src/main/kotlin/sample", "p")
local kfile = kroot .. "/src/main/kotlin/sample/DebugMain.kt"
vim.fn.writefile(
  { "package sample", "fun main() {", "    Thread.sleep(6000)", "    val result = 2 + 3", "    println(result)", "}" },
  kfile
)
local klib = vim.fn.stdpath("data") .. "/mason/packages/kotlin-language-server/server/lib"
local kstd = vim.fn.glob(klib .. "/kotlin-stdlib-*.jar", false, true)[1]
local compiled = vim
  .system({
    "C:/My/data/Jir/home/21/temurin/bin/java.exe",
    "-cp",
    klib .. "/*",
    "org.jetbrains.kotlin.cli.jvm.K2JVMCompiler",
    "-no-stdlib",
    "-no-reflect",
    "-classpath",
    kstd,
    "-d",
    kroot .. "/build/classes/kotlin/main",
    kfile,
  })
  :wait()
assert(compiled.code == 0, compiled.stderr)
vim.cmd("tcd " .. vim.fn.fnameescape(root .. "/kotlin"))
vim.cmd("edit " .. vim.fn.fnameescape(root .. "/kotlin/src/main/kotlin/sample/DebugMain.kt"))
local buf = api.nvim_get_current_buf()
local lib = vim.fn.stdpath("data") .. "/mason/packages/kotlin-language-server/server/lib"
local std = vim.fn.glob(lib .. "/kotlin-stdlib-*.jar", false, true)[1]
local job = vim.fn.jobstart({
  "C:/My/data/Jir/home/21/temurin/bin/java.exe",
  "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=127.0.0.1:5005",
  "-cp",
  root .. "/kotlin/build/classes/kotlin/main;" .. std,
  "sample.DebugMainKt",
})
assert(job > 0)
vim.wait(300)
api.nvim_win_set_cursor(0, { 4, 0 })
dap.set_breakpoint()
debug({
  type = "kotlin",
  request = "attach",
  name = "Kotlin validation",
  projectRoot = root .. "/kotlin",
  hostName = "localhost",
  port = 5005,
  timeout = 10000,
  sourcePaths = { root .. "/kotlin" },
}, "KOTLIN_DAP")
vim.fn.jobstop(job)
for _, c in ipairs(vim.lsp.get_clients()) do
  c:stop(true)
end
vim.cmd("qa!")

