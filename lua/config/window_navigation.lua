local M = {}
local api = vim.api

local function anchor(win)
  local seen = {}
  while api.nvim_win_is_valid(win) and not seen[win] do
    seen[win] = true
    local config = api.nvim_win_get_config(win)
    if config.relative == "" then
      return win
    end
    if config.relative ~= "win" or not config.win then
      return win
    end
    win = config.win
  end
  return win
end

function M.move(direction)
  vim.cmd.stopinsert()
  local source = anchor(api.nvim_get_current_win())
  if vim.w[source].editor_bar_source and api.nvim_win_is_valid(vim.w[source].editor_bar_source) then
    source = vim.w[source].editor_bar_source
  end
  api.nvim_set_current_win(source)
  vim.cmd("wincmd " .. direction)
  local target = api.nvim_get_current_win()
  -- 标签栏和底边占用原生布局行，继续沿方向寻找可交互区域。
  local seen = {}
  while vim.w[target].editor_bar_source do
    if seen[target] then
      target = source
      api.nvim_set_current_win(source)
      break
    end
    seen[target] = true
    vim.cmd("wincmd " .. direction)
    target = api.nvim_get_current_win()
  end
  -- 分屏中真正可交互的内容可能是编辑卡片、文件树或终端。
  local selected, priority = target, 0
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    local config = api.nvim_win_get_config(win)
    if config.relative ~= "" and config.focusable ~= false and anchor(win) == target then
      local ft = vim.bo[api.nvim_win_get_buf(win)].filetype
      local rank = (ft == "snacks_picker_list" or ft == "snacks_terminal") and 3
        or (vim.w[win].editor_card_source and 2 or 1)
      if ft == "neominimap" then rank = 0 end
      if rank > priority then
        selected, priority = win, rank
      end
    end
  end
  api.nvim_set_current_win(selected)
end

function M.resize(command)
  local source = anchor(api.nvim_get_current_win())
  api.nvim_win_call(source, function()
    vim.cmd(command)
  end)
  require("config.editor_card").refresh()
  local markdown = package.loaded["config.markdown_split"]
  if markdown then
    for _, pair in pairs(markdown.pairs) do
      markdown.update(pair)
    end
  end
  vim.schedule(function()
    local islands = require("config.island_ui")
    if islands.apply then
      islands.apply()
    end
  end)
end

return M
