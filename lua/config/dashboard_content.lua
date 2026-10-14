local M = {}

-- 保留目录名，长路径从中间省略，避免每段都变成难辨认的首字母。
local function compact(path, width)
  path = vim.fs.normalize(vim.fn.fnamemodify(path, ":~"))
  if vim.fn.strdisplaywidth(path) <= width then
    return path
  end
  local chars = vim.fn.strchars(path)
  local left, right = math.floor(width / 3), math.floor(width * 2 / 3) - 1
  while left > 0 and right > 0 do
    local value = vim.fn.strcharpart(path, 0, left) .. "…" .. vim.fn.strcharpart(path, chars - right, right)
    if vim.fn.strdisplaywidth(value) <= width then
      return value
    end
    right = right - 1
  end
  return "…"
end

function M.projects()
  local items = Snacks.dashboard.sections.projects({ dirs = require("config.recent_projects").all(), limit = 5,
    action = function(dir) require("config.recent_projects").switch(dir) end })
  for _, item in ipairs(items) do
    local dir = item.file
    local name = vim.fs.basename(dir)
    item.desc = {
      { name, hl = "file" },
      { "  ·  " .. compact(vim.fs.dirname(dir), math.max(12, 54 - vim.fn.strdisplaywidth(name))), hl = "dir" },
    }
    item.file, item.icon = nil, " "
  end
  return items
end

function M.files()
  local items = Snacks.dashboard.sections.recent_files({ limit = 3 })()
  for _, item in ipairs(items) do
    local file = item.file
    item.desc = {
      { vim.fs.basename(file), hl = "file" },
      { "\n" .. compact(vim.fs.dirname(file), 55), hl = "dir" },
    }
    item.file, item.icon = nil, " "
  end
  return items
end

return M
