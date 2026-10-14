-- 按项目目录保存主题；不向项目仓库写入配置文件。
local M = {}
local themes_file = vim.fn.stdpath("state") .. "/project-themes.json"
local default_theme = "tokyonight-storm"
local themes = {
  { name = "tokyonight-storm", label = "TokyoNight Storm · 深色", plugin = "tokyonight.nvim" },
  { name = "tokyonight-night", label = "TokyoNight Night · 深色", plugin = "tokyonight.nvim" },
  { name = "tokyonight-moon", label = "TokyoNight Moon · 深色", plugin = "tokyonight.nvim" },
  { name = "tokyonight-day", label = "TokyoNight Day · 浅色", plugin = "tokyonight.nvim", light = true },
  { name = "catppuccin-mocha", label = "Catppuccin Mocha · 深色", plugin = "catppuccin" },
  { name = "catppuccin-macchiato", label = "Catppuccin Macchiato · 深色", plugin = "catppuccin" },
  { name = "catppuccin-frappe", label = "Catppuccin Frappé · 深色", plugin = "catppuccin" },
  { name = "catppuccin-latte", label = "Catppuccin Latte · 浅色", plugin = "catppuccin", light = true },
  { name = "kanagawa-wave", label = "Kanagawa Wave · 深色", plugin = "kanagawa.nvim", colors_name = "kanagawa" },
  { name = "kanagawa-dragon", label = "Kanagawa Dragon · 深色", plugin = "kanagawa.nvim", colors_name = "kanagawa" },
  { name = "kanagawa-lotus", label = "Kanagawa Lotus · 浅色", plugin = "kanagawa.nvim", colors_name = "kanagawa", light = true },
  { name = "gruvbox-dark", label = "Gruvbox · 深色", plugin = "gruvbox.nvim", scheme = "gruvbox" },
  { name = "gruvbox-light", label = "Gruvbox · 浅色", plugin = "gruvbox.nvim", scheme = "gruvbox", light = true },
  { name = "rose-pine-main", label = "Rosé Pine · 深色", plugin = "rose-pine", colors_name = "rose-pine" },
  { name = "rose-pine-moon", label = "Rosé Pine Moon · 深色", plugin = "rose-pine", colors_name = "rose-pine" },
  { name = "rose-pine-dawn", label = "Rosé Pine Dawn · 浅色", plugin = "rose-pine", colors_name = "rose-pine", light = true },
}

local themes_by_name = {}
for _, variant in ipairs({ "nightfox", "duskfox", "nordfox", "terafox", "carbonfox", "dayfox", "dawnfox" }) do
  local light = variant == "dayfox" or variant == "dawnfox"
  themes[#themes + 1] = { name = variant, label = "Nightfox / " .. variant .. (light and " · 浅色" or " · 深色"),
    plugin = "nightfox.nvim", light = light }
end
for _, variant in ipairs({ "github_dark", "github_dark_dimmed", "github_dark_high_contrast", "github_light", "github_light_high_contrast" }) do
  local light = variant:find("light", 1, true) ~= nil
  themes[#themes + 1] = { name = variant, label = "GitHub / " .. variant:gsub("github_", "") .. (light and " · 浅色" or " · 深色"),
    plugin = "github-nvim-theme", light = light }
end
vim.list_extend(themes, {
  { name = "everforest-dark", label = "Everforest 森林绿 · 深色", plugin = "everforest", scheme = "everforest" },
  { name = "everforest-light", label = "Everforest 森林绿 · 浅色", plugin = "everforest", scheme = "everforest", light = true },
  { name = "nord", label = "Nord 北欧 · 深色", plugin = "nord.nvim" },
  { name = "dracula", label = "Dracula · 深色", plugin = "dracula.nvim" },
  { name = "vscode-dark", label = "VS Code · 深色", plugin = "vscode.nvim", scheme = "vscode" },
  { name = "vscode-light", label = "VS Code · 浅色", plugin = "vscode.nvim", scheme = "vscode", light = true },
  { name = "oxocarbon-dark", label = "Oxocarbon / IBM Carbon · 深色", plugin = "oxocarbon.nvim", scheme = "oxocarbon" },
  { name = "oxocarbon-light", label = "Oxocarbon / IBM Carbon · 浅色", plugin = "oxocarbon.nvim", scheme = "oxocarbon", light = true },
})
for _, theme in ipairs(themes) do
  themes_by_name[theme.name] = theme
end

local function use_colorscheme(name)
  return pcall(function()
    local theme = assert(themes_by_name[name])
    require("lazy").load({ plugins = { theme.plugin } })
    vim.o.background = theme.light and "light" or "dark"
    vim.cmd.colorscheme(theme.scheme or theme.name)
  end)
end

local function project_key(path)
  return vim.fs.normalize(path):lower() -- Windows 路径不区分大小写
end

local function read_settings()
  local ok, lines = pcall(vim.fn.readfile, themes_file)
  if not ok or #lines == 0 then
    return {}
  end
  local decoded_ok, settings = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded_ok and type(settings) == "table" and settings or {}
end

local function save_settings(settings)
  vim.fn.mkdir(vim.fn.fnamemodify(themes_file, ":h"), "p")
  local ok, err = pcall(vim.fn.writefile, { vim.json.encode(settings) }, themes_file)
  if not ok then
    vim.notify("保存项目主题失败：" .. tostring(err), vim.log.levels.ERROR)
  end
  return ok
end

function M.project()
  return M.active or vim.fs.normalize(vim.fn.getcwd())
end

function M.startup_colorscheme()
  local file = vim.api.nvim_buf_get_name(0)
  local path = require("config.recent_projects").root_for_file(file) or vim.fn.getcwd()
  M.apply(path)
end

function M.apply(path)
  if not path then
    return
  end
  path = vim.fs.normalize(path)
  M.active = path
  local saved = read_settings()[project_key(path)]
  local name = themes_by_name[saved] and saved or default_theme
  local theme = themes_by_name[name]
  if M.applied ~= name or vim.g.colors_name ~= (theme.colors_name or theme.scheme or name)
    or vim.o.background ~= (theme.light and "light" or "dark") then
    local ok, err = use_colorscheme(name)
    if not ok then
      vim.notify("加载项目主题失败：" .. tostring(err), vim.log.levels.WARN)
    else
      M.applied = name
    end
  end
end

function M.set(name, project)
  if name ~= nil and not themes_by_name[name] then
    return false
  end
  local path = project or M.project()
  local desired = name or default_theme
  local ok, err = use_colorscheme(desired)
  if not ok then
    vim.notify("切换主题失败：" .. tostring(err), vim.log.levels.ERROR)
    return false
  end
  M.applied = desired
  local settings = read_settings()
  settings[project_key(path)] = name
  if save_settings(settings) then
    vim.notify("已为项目 " .. vim.fs.basename(path) .. " 设置主题：" .. desired)
    return true
  end
  return false
end

function M.pick()
  local project = M.project()
  local current = read_settings()[project_key(project)]
  local original = themes_by_name[current] and current or default_theme
  local preview_name
  local choices = { { name = nil, label = "使用默认主题 · TokyoNight Storm" } }
  vim.list_extend(choices, themes)
  M.previewing = true
  return Snacks.picker.select(choices, {
    prompt = "预览项目主题（回车确认 / Esc取消）：" .. vim.fs.basename(project),
    format_item = function(item)
      return (item.name == current and "✓ " or "  ") .. item.label
    end,
    snacks = {
      on_change = function(_, item)
        local choice = item and item.item
        if not choice then
          return
        end
        local name = choice.name or default_theme
        if preview_name ~= name then
          local ok, err = use_colorscheme(name)
          if ok then
            preview_name = name
          else
            vim.notify("预览主题失败：" .. tostring(err), vim.log.levels.WARN)
          end
        end
      end,
      win = { input = { keys = { ["<Esc>"] = { "close", mode = { "n", "i" } } } } },
    },
  }, function(choice)
    M.previewing = false
    if not choice or not M.set(choice.name, project) then
      local ok = use_colorscheme(original)
      if ok then
        M.applied = original
      end
    end
  end)
end

function M.setup()
  if not M.active then
    M.startup_colorscheme()
  end
  local group = vim.api.nvim_create_augroup("project_theme", { clear = true })
  vim.api.nvim_create_autocmd({ "DirChanged", "SessionLoadPost" }, {
    group = group,
    callback = function()
      -- 选中的工作目录是项目边界；旧缓冲区和子模块不再覆盖它。
      M.directory_project = true
      M.apply(vim.fn.getcwd())
    end,
  })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(args)
      if M.previewing or M.directory_project or project_key(M.active) == project_key(vim.fn.getcwd())
        or vim.bo[args.buf].buftype ~= "" then
        return
      end
      local root = require("config.recent_projects").root_for_file(vim.api.nvim_buf_get_name(args.buf))
      if root and vim.fs.normalize(root) ~= M.active then
        M.apply(root)
      end
    end,
  })
  vim.api.nvim_create_user_command("ProjectTheme", M.pick, { desc = "选择当前项目主题" })
  vim.api.nvim_create_user_command("ProjectThemeReset", function()
    M.set(nil)
  end, { desc = "恢复当前项目默认主题" })
end

return M
