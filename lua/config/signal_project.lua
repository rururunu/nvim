local M = {}
function M.matches(root)
  return vim.fn.filereadable(
    root .. "/service/src/main/java/org/whispersystems/textsecuregcm/WhisperServerService.java"
  ) == 1 and vim.fn.filereadable(root .. "/pom.xml") == 1
end
local function settings_path(root)
  return vim.fn.stdpath("state") .. "/project-run/" .. vim.fn.sha256(vim.fs.normalize(root):lower()) .. ".json"
end
function M.settings(root)
  local defaults = {
    java_home = "C:/My/data/Jir/home/26/temurin",
    config = root .. "/service/config/sample.yml",
    secrets = root .. "/service/config/sample-secrets-bundle.yml",
    port = 5005,
  }
  local ok, data = pcall(vim.fn.readfile, settings_path(root))
  if ok then
    local parsed, value = pcall(vim.json.decode, table.concat(data, "\n"))
    if parsed and type(value) == "table" then
      defaults = vim.tbl_extend("force", defaults, value)
    end
  end
  return defaults
end
function M.setup_project()
  local root = require("config.project_tasks").root()
  if not M.matches(root) then
    vim.notify("当前项目不是 Signal-Server")
    return
  end
  local values = M.settings(root)
  local fields = {
    { "java_home", "Signal JDK 26 目录：", "dir" },
    { "config", "Signal 服务配置文件：", "file" },
    { "secrets", "Signal secrets bundle 文件：", "file" },
  }
  local function step(i)
    local field = fields[i]
    if not field then
      vim.fn.mkdir(vim.fs.dirname(settings_path(root)), "p")
      vim.fn.writefile({ vim.json.encode(values) }, settings_path(root))
      vim.notify("Signal 运行配置已保存（只记录路径，不读取配置内容）")
      return
    end
    vim.ui.input({ prompt = field[2], default = values[field[1]], completion = field[3] }, function(value)
      if value then
        values[field[1]] = vim.fs.normalize(value)
        step(i + 1)
      end
    end)
  end
  step(1)
end
function M.tasks(root)
  local settings = M.settings(root)
  local env = { JAVA_HOME = settings.java_home, PATH = settings.java_home .. "/bin;" .. vim.env.PATH }
  local mvn = vim.fn.filereadable(root .. "/mvnw.cmd") == 1 and root .. "/mvnw.cmd" or vim.fn.exepath("mvn")
  local function task(name, args)
    return { name = name, cmd = mvn, args = args, cwd = root, env = env }
  end
  local base = { "-B", "-Dstyle.color=never", "-pl", "service", "-am" }
  local function args(extra)
    return vim.list_extend(vim.deepcopy(base), extra)
  end
  return {
    task("Signal · 编译 service 及依赖模块", args({ "-DskipTests", "compile" })),
    task("Signal · 打包 service 及依赖模块", args({ "-DskipTests", "package" })),
    task(
      "Signal · UtilTest（不启动业务服务）",
      args({ "-Dtest=UtilTest", "-Dsurefire.failIfNoSpecifiedTests=false", "test" })
    ),
    task("Signal · service 测试集（需要项目依赖环境）", args({ "test" })),
    { name = "Signal · 启动服务（使用已打包 JAR）", signal_start = true, cwd = root },
    { name = "Signal · 启动服务并监听调试端口", signal_start = true, debug = true, cwd = root },
    { name = "Signal · 设置 JDK / 配置文件路径", signal_setup = true },
  }
end
function M.launch(root, debug)
  local settings = M.settings(root)
  for _, path in ipairs({ settings.config, settings.secrets, settings.java_home .. "/bin/java.exe" }) do
    if vim.fn.filereadable(path) ~= 1 then
      vim.notify("运行文件不存在：" .. path .. "；请先执行 :SignalSetup", vim.log.levels.ERROR)
      return
    end
  end
  local jars = vim.fn.glob(root .. "/service/target/TextSecureServer-*.jar", false, true)
  jars = vim.tbl_filter(function(path)
    return not path:match("%-tests%.jar$") and not path:match("original%-")
  end, jars)
  if #jars ~= 1 then
    vim.notify("请先打包，并确保 service/target 中只有一个服务 JAR", vim.log.levels.ERROR)
    return
  end
  local args = {
    "-Dfile.encoding=UTF-8",
    "-Dsun.stdout.encoding=UTF-8",
    "-Dsun.stderr.encoding=UTF-8",
    "-Dsecrets.bundle.filename=" .. settings.secrets,
  }
  if debug then
    args[#args + 1] = "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=127.0.0.1:" .. settings.port
  end
  vim.list_extend(args, { "-jar", jars[1], "server", settings.config })
  return require("config.project_tasks").run({
    name = debug and "Signal · 调试服务" or "Signal · 服务",
    cmd = settings.java_home .. "/bin/java.exe",
    args = args,
    cwd = root,
  })
end
function M.debug()
  local root = require("config.project_tasks").root()
  local java = vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })[1]
  if not java then
    vim.notify("请先打开 Signal Java 源文件，等待 Java LSP 就绪", vim.log.levels.WARN)
    return
  end
  require("jdtls.dap").setup_dap()
  require("dap").run({
    type = "java",
    request = "attach",
    name = "Signal · 附加本机 JVM",
    hostName = "127.0.0.1",
    port = M.settings(root).port,
  })
end
return M
