local M = {}
local api = vim.api

function M.health()
  local lines =
    { "# 开发环境检查", "", "项目：" .. require("config.project_tasks").root(), "", "## 命令行工具" }
  for _, tool in ipairs({
    "git",
    "lazygit",
    "rg",
    "fd",
    "java",
    "javac",
    "mvn",
    "gradle",
    "cargo",
    "rustc",
    "rust-analyzer",
    "kotlinc",
    "node",
    "python",
  }) do
    local path = vim.fn.exepath(tool)
    lines[#lines + 1] = (path ~= "" and "✓ " or "缺少：")
      .. tool
      .. (path ~= "" and "  " .. path or "（项目 wrapper 可替代部分构建工具）")
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "## 语言服务"
  for _, client in ipairs(vim.lsp.get_clients()) do
    lines[#lines + 1] = client.name .. " · " .. (client.config.root_dir or "无根目录")
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "详细检查：:checkhealth；LSP 日志：:LspLog；任务列表：:OverseerOpen"
  vim.cmd("botright new")
  local buf = api.nvim_get_current_buf()
  vim.bo[buf].buftype, vim.bo[buf].bufhidden = "nofile", "wipe"
  api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "text"
  vim.bo[buf].modifiable = false
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "关闭检查报告" })
end

local function copy(source, target)
  vim.fn.mkdir(vim.fs.dirname(target), "p")
  local ok, err = vim.uv.fs_copyfile(source, target)
  assert(ok, err)
end
local files = { "init.lua", "lazyvim.json", "lazy-lock.json", "README.md", "stylua.toml", ".stylua.toml" }
local function walk(dir, relative, result)
  local scan = vim.uv.fs_scandir(dir)
  if not scan then
    return
  end
  while true do
    local name, kind = vim.uv.fs_scandir_next(scan)
    if not name then
      break
    end
    local rel = relative .. "/" .. name
    if kind == "directory" then
      walk(dir .. "/" .. name, rel, result)
    elseif kind == "file" then
      result[#result + 1] = rel
    end
  end
end

function M.backup()
  local config = vim.fn.stdpath("config")
  local target = vim.fn.stdpath("state")
    .. "/config-backups/"
    .. os.date("%Y%m%d-%H%M%S")
    .. "-"
    .. vim.fn.sha256(tostring(vim.uv.hrtime())):sub(1, 8)
  local list = vim.deepcopy(files)
  walk(config .. "/lua", "lua", list)
  for _, file in ipairs(list) do
    if vim.fn.filereadable(config .. "/" .. file) == 1 then
      copy(config .. "/" .. file, target .. "/" .. file)
    end
  end
  vim.fn.writefile({ vim.json.encode(list) }, target .. "/manifest.json")
  vim.notify("配置备份已保存：" .. target)
  return target
end

function M.restore()
  local backups = vim.fn.glob(vim.fn.stdpath("state") .. "/config-backups/*", false, true)
  table.sort(backups, function(a, b)
    return a > b
  end)
  vim.ui.select(backups, { prompt = "选择要恢复的配置备份", format_item = vim.fs.basename }, function(path)
    if not path then
      return
    end
    vim.ui.select(
      { "取消", "备份当前配置并恢复所选版本" },
      { prompt = "恢复后需重启 Neovim" },
      function(choice)
        if choice ~= "备份当前配置并恢复所选版本" then
          return
        end
        M.backup()
        local list = vim.json.decode(table.concat(vim.fn.readfile(path .. "/manifest.json"), "\n"))
        local keep = {}
        for _, file in ipairs(list) do
          keep[file] = true
        end
        local current = {}
        walk(vim.fn.stdpath("config") .. "/lua", "lua", current)
        for _, file in ipairs(current) do
          if not keep[file] then
            assert(vim.uv.fs_unlink(vim.fn.stdpath("config") .. "/" .. file))
          end
        end
        for _, file in ipairs(list) do
          if not file:find("..", 1, true) and vim.fn.filereadable(path .. "/" .. file) == 1 then
            copy(path .. "/" .. file, vim.fn.stdpath("config") .. "/" .. file)
          end
        end
        vim.notify("配置已恢复，请重启 Neovim。恢复前的配置已另存为新备份。")
      end
    )
  end)
end

function M.menu()
  local actions = {
    {
      "选择项目",
      function()
        require("config.recent_projects").open_picker()
      end,
    },
    {
      "查找文件",
      function()
        Snacks.picker.files({ cwd = require("config.project_tasks").root() })
      end,
    },
    {
      "搜索内容",
      function()
        Snacks.picker.grep({ cwd = require("config.project_tasks").root() })
      end,
    },
    {
      "运行 / 构建 / 测试",
      function()
        require("config.project_tasks").pick()
      end,
    },
    {
      "任务列表与输出",
      function()
        require("overseer").toggle()
      end,
    },
    {
      "停止任务",
      function()
        require("config.project_tasks").stop()
      end,
    },
    {
      "重跑失败的测试任务",
      function()
        require("config.project_tasks").failed_tests()
      end,
    },
    {
      "错误列表",
      function()
        vim.cmd("copen")
      end,
    },
    {
      "调试：启动 / 继续",
      function()
        require("dap").continue()
      end,
    },
    {
      "Git · LazyGit",
      function()
        Snacks.lazygit({ cwd = vim.fn.getcwd(), override = false })
      end,
    },
    { "环境检查", M.health },
    { "备份配置", M.backup },
    { "恢复配置备份", M.restore },
    {
      "保存工作区会话",
      function()
        require("config.workspace").save()
      end,
    },
    {
      "恢复工作区会话",
      function()
        require("config.workspace").restore()
      end,
    },
  }
  vim.ui.select(actions, {
    prompt = "开发工作台",
    format_item = function(item)
      return item[1]
    end,
  }, function(item)
    if item then
      item[2]()
    end
  end)
end

function M.setup()
  api.nvim_create_user_command("SignalSetup", function()
    require("config.signal_project").setup_project()
  end, { desc = "设置 Signal-Server 的 JDK 与运行配置文件路径" })
  for name, action in pairs({
    Workbench = M.menu,
    DevHealth = M.health,
    ConfigBackup = M.backup,
    ConfigRestore = M.restore,
    ProjectRun = function()
      require("config.project_tasks").pick()
    end,
    ProjectRerun = function()
      require("config.project_tasks").rerun()
    end,
    ProjectStop = function()
      require("config.project_tasks").stop()
    end,
    WorkspaceSave = function()
      require("config.workspace").save()
    end,
    WorkspaceRestore = function()
      require("config.workspace").restore()
    end,
  }) do
    api.nvim_create_user_command(name, action, {})
  end
end
return M
