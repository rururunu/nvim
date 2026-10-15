local M = { items = {}, serial = 0 }

-- 原生 winbar 位于圆角边框内部，鼠标事件由 Neovim 处理。
function M.winbar()
  local result = { "%#IslandSurface# " }
  M.hitboxes = {}
  local column = 2
  local width = vim.api.nvim_win_get_width(vim.g.statusline_winid or 0)
  for _, item in ipairs(M.items) do
    if item.term:buf_valid() then
      local text = (item == M.current and " ▎ " or "   ") .. " 终端 " .. item.id .. "  "
      local size = vim.fn.strdisplaywidth(text)
      if column + size > width then
        break
      end
      result[#result + 1] = (item == M.current and "%#IslandTabActive#" or "%#IslandTab#")
        .. "%"
        .. item.id
        .. "@v:lua.TerminalTabClick@"
        .. text
        .. "%T"
      M.hitboxes[#M.hitboxes + 1] = { first = column, last = column + size - 1, item = item }
      column = column + size
    end
  end
  result[#result + 1] = "%#IslandSurface#"
  return table.concat(result)
end

_G.TerminalTabsBar = function()
  return M.winbar()
end
_G.TerminalTabClick = function(id, _, button)
  if button ~= "l" then
    return
  end
  vim.schedule(function()
    for _, item in ipairs(M.items) do
      if item.id == id then
        M.show(item)
        return
      end
    end
  end)
end

local function valid()
  M.items = vim.tbl_filter(function(item)
    return item.term:buf_valid()
  end, M.items)
  return M.items
end

function M.show(item)
  if not item then
    return
  end
  local dock = require("config.docked_terminal")
  dock.switching = true
  for _, other in ipairs(valid()) do
    if other ~= item and other.term:win_valid() then
      other.term:hide()
    end
  end
  M.current = item
  item.term.opts.title = ""
  item.term:show()
  item.term:update()
  item.term:focus()
  dock.switching = false
  vim.cmd("redrawstatus!")
  vim.cmd.startinsert()
end

function M.new()
  local dock = require("config.docked_terminal")
  dock.switching = true
  for _, item in ipairs(valid()) do
    if item.term:win_valid() then
      item.term:hide()
    end
  end
  M.serial = M.serial + 1
  local item = { id = M.serial, cwd = vim.fn.getcwd(), tab = vim.api.nvim_get_current_tabpage() }
  local keys = {
    panel = {
      "<F7>",
      function()
        M.toggle()
      end,
      mode = { "n", "t" },
      desc = "隐藏终端面板（保留进程）",
    },
    next_tab = {
      "<A-Right>",
      function()
        M.cycle(1)
      end,
      mode = { "n", "t" },
      desc = "下一个终端标签",
    },
    prev_tab = {
      "<A-Left>",
      function()
        M.cycle(-1)
      end,
      mode = { "n", "t" },
      desc = "上一个终端标签",
    },
  }
  item.term = Snacks.terminal.open(nil, {
    count = M.serial + 1000,
    cwd = item.cwd,
    win = { keys = keys, title = "", wo = { winbar = "%!v:lua.TerminalTabsBar()" } },
  })
  table.insert(M.items, item)
  item.term:on("TermClose", function()
    local visible = item.term:win_valid()
    vim.schedule(function()
      if vim.v.exiting ~= vim.NIL and vim.v.exiting ~= nil then
        return
      end
      for i, entry in ipairs(M.items) do
        if entry == item then
          table.remove(M.items, i)
          break
        end
      end
      if M.current == item then
        M.current = M.items[#M.items]
        if visible then
          M.show(M.current)
        end
      end
    end)
  end, { buf = true })
  M.show(item)
  return item
end

function M.toggle()
  valid()
  if M.current and M.current.term:win_valid() then
    vim.cmd.stopinsert()
    M.current.term:hide()
  elseif M.current and M.current.term:buf_valid() then
    M.show(M.current)
  elseif #M.items > 0 then
    M.show(M.items[#M.items])
  else
    M.new()
  end
end

function M.cycle(delta)
  local items = valid()
  if #items == 0 then
    return
  end
  local index = 1
  for i, item in ipairs(items) do
    if item == M.current then
      index = i
      break
    end
  end
  M.show(items[(index - 1 + delta) % #items + 1])
end

function M.pick()
  vim.ui.select(valid(), {
    prompt = "终端标签",
    format_item = function(item)
      return "终端 " .. item.id .. " · " .. item.cwd
    end,
  }, function(item)
    if item then
      M.show(item)
    end
  end)
end

return M
