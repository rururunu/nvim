-- 记录实际打开过的项目目录，供启动页跨 Neovim 重启显示。
local M = {}
local history_file = vim.fn.stdpath("state") .. "/recent-projects.json"
local markers = {
  ".git",
  ".hg",
  "package.json",
  "Cargo.toml",
  "rust-project.json",
  "pyproject.toml",
  "go.mod",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
  "build.xml",
  "CMakeLists.txt",
}

local function is_dir(path)
  local stat = path and vim.uv.fs_stat(path)
  return stat and stat.type == "directory"
end

local function path_key(path)
  local normalized = vim.fs.normalize(vim.uv.fs_realpath(path) or path)
  return vim.fn.has("win32") == 1 and normalized:lower() or normalized
end

function M.list()
  local ok, lines = pcall(vim.fn.readfile, history_file)
  if not ok or #lines == 0 then
    return {}
  end
  local decoded_ok, paths = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded_ok or type(paths) ~= "table" then
    return {}
  end
  local result, seen = {}, {}
  for _, path in ipairs(paths) do
    if type(path) == "string" and is_dir(path) and not seen[path_key(path)] then
      result[#result + 1] = vim.fs.normalize(vim.uv.fs_realpath(path) or path)
      seen[path_key(path)] = true
    end
  end
  return result
end

function M.record(path)
  if not is_dir(path) then
    return
  end
  path = vim.fs.normalize(path)
  local paths = { path }
  for _, old in ipairs(M.list()) do
    if path_key(old) ~= path_key(path) then
      paths[#paths + 1] = old
    end
  end
  vim.fn.mkdir(vim.fn.fnamemodify(history_file, ":h"), "p")
  pcall(vim.fn.writefile, { vim.json.encode(paths) }, history_file)
end

function M.all()
  local dirs, seen = M.list(), {}
  for _, dir in ipairs(dirs) do
    seen[path_key(dir)] = true
  end
  for file in Snacks.dashboard.oldfiles() do
    local root = Snacks.git.get_root(file)
    if root and is_dir(root) and not seen[path_key(root)] then
      dirs[#dirs + 1] = vim.fs.normalize(vim.uv.fs_realpath(root) or root)
      seen[path_key(root)] = true
    end
  end
  return dirs
end

-- 独立的可搜索窗口：列出全部已记录项目及最近文件对应的 Git 项目。
function M.switch(path)
  if not is_dir(path) then
    vim.notify("项目目录不存在：" .. tostring(path), vim.log.levels.WARN)
    return
  end
  path = vim.fs.normalize(path)
  pcall(function()
    require("config.workspace").save()
  end)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local saved = vim.t[tab].workspace_path
    if saved and path_key(saved) == path_key(path) then
      vim.api.nvim_set_current_tabpage(tab)
      vim.cmd("tcd " .. vim.fn.fnameescape(path))
      require("config.project_theme").apply(path)
      return
    end
  end
  -- 浮窗的窗口局部目录在关闭后会丢失；在真实窗口中设置标签页目录。
  local markdown = require("config.markdown_split")
  markdown.close(vim.api.nvim_get_current_tabpage())
  require("config.editor_card").clear()
  for _, picker in ipairs(Snacks.picker.get()) do
    if picker.opts.source == "explorer" then
      picker:close()
    end
  end
  local current = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(current).relative ~= "" then
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_config(win).relative == "" then
        vim.api.nvim_set_current_win(win)
        break
      end
    end
  end
  local buf = vim.api.nvim_get_current_buf()
  local empty = vim.api.nvim_buf_get_name(buf) == ""
    and not vim.bo[buf].modified
    and vim.bo[buf].buftype == ""
    and #vim.api.nvim_tabpage_list_wins(0) == 1
  if not empty and vim.bo[buf].filetype ~= "snacks_dashboard" then
    vim.cmd("tabnew")
  end
  vim.t.workspace_path = path
  vim.cmd("tcd " .. vim.fn.fnameescape(path))
  M.record(path)
  require("config.project_theme").apply(path)
  -- 每个入口使用明确的 cwd，避免旧缓冲区的项目根目录覆盖选择结果。
  local workspace = require("config.workspace")
  if workspace.exists(path) and workspace.restore({ new_tab = false, quiet = true }) then
    return
  end
  Snacks.explorer({ cwd = path })
  Snacks.picker.files({ cwd = path, title = "项目文件 · " .. vim.fs.basename(path) })
end

function M.open_picker()
  Snacks.picker.projects({
    title = "所有项目",
    projects = M.all(),
    dev = {}, -- 不扫描无关目录
    recent = false,
    confirm = function(picker, item)
      if not item then
        return
      end
      local path = item.file
      picker:close()
      vim.schedule(function()
        M.switch(path)
      end)
    end,
  })
end

function M.record_file(file)
  if file == "" or vim.fn.filereadable(file) == 0 then
    return
  end
  M.record(M.root_for_file(file))
end

function M.root_for_file(file)
  if file == "" then
    return nil
  end
  return vim.fs.root(file, markers) or vim.fs.dirname(file)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("recent_projects", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter", "BufWritePost" }, {
    group = group,
    callback = function(args)
      if vim.bo[args.buf].buftype == "" then
        M.record_file(vim.api.nvim_buf_get_name(args.buf))
      end
    end,
  })
  vim.api.nvim_create_autocmd("DirChanged", {
    group = group,
    callback = function()
      local cwd = vim.fn.getcwd()
      if vim.fs.root(cwd, markers) == vim.fs.normalize(cwd) then
        M.record(cwd)
      end
    end,
  })
  local current = vim.api.nvim_get_current_buf()
  if vim.bo[current].buftype == "" then
    M.record_file(vim.api.nvim_buf_get_name(current))
  end
  local cwd = vim.fn.getcwd()
  if vim.fs.root(cwd, markers) == vim.fs.normalize(cwd) then
    M.record(cwd)
  end
end

return M
