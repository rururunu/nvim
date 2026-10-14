local M = {}
local api = vim.api

-- 原生分屏分配空间，内部窗口负责圆角边框；终端进程由 Snacks 管理。
function M.open(cmd, opts)
  local root
  local function container()
    if root and api.nvim_win_is_valid(root) then return root end
    vim.cmd("botright new")
    root = api.nvim_get_current_win()
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.buflisted = false
    vim.bo.filetype = "terminal_card_container"
    vim.wo.winfixheight = true
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "no"
    vim.wo.statuscolumn = ""
    vim.wo.winbar = ""
    api.nvim_win_set_height(root, math.max(6, math.floor(vim.o.lines * 0.30)))
    return root
  end
  local function geometry()
    local win = container()
    return { position = "float", relative = "win", win = win, row = 0, col = 0,
      width = function() return math.max(1, api.nvim_win_get_width(win) - 2) end,
      height = function() return math.max(1, api.nvim_win_get_height(win) - 2) end }
  end
  local on_close = opts.win.on_close
  opts.override = false
  opts.win.keys = opts.win.keys or {}
  for _, direction in ipairs({ "h", "j", "k", "l" }) do
    opts.win.keys["nav_" .. direction] = { "<C-" .. direction .. ">", function()
      require("config.window_navigation").move(direction)
    end, mode = "t", desc = "切换到相邻区域" }
  end
  opts.win = vim.tbl_deep_extend("force", opts.win, geometry())
  opts.win.on_close = function(self)
    local closed_root = root
    root = nil
    if closed_root and api.nvim_win_is_valid(closed_root) then
      pcall(api.nvim_win_close, closed_root, true)
    end
    if on_close then on_close(self) end
  end
  local term = Snacks.terminal.open(cmd, opts)
  local show = term.show
  term.show = function(self)
    self.opts = vim.tbl_deep_extend("force", self.opts, geometry())
    local result = show(self)
    if self.win then vim.w[self.win].terminal_card_source = root end
    return result
  end
  vim.w[term.win].terminal_card_source = root
  term:on({ "WinResized", "WinEnter" }, function(self)
    vim.schedule(function()
      if root and api.nvim_win_is_valid(root) and self:win_valid() then
        self:update()
        local islands = require("config.island_ui")
        if islands.apply then islands.apply() end
      end
    end)
  end)
  return term
end

return M
