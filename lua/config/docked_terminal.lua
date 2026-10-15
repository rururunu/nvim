local M = { roots = {} }
local api = vim.api

-- 原生分屏分配空间，内部窗口负责圆角边框；终端进程由 Snacks 管理。
function M.open(cmd, opts)
  local root
  local tab = api.nvim_get_current_tabpage()
  local function container()
    if M.roots[tab] and api.nvim_win_is_valid(M.roots[tab]) then
      root = M.roots[tab]
      return root
    end
    if root and api.nvim_win_is_valid(root) then
      return root
    end
    vim.cmd("botright new")
    root = api.nvim_get_current_win()
    M.root = root
    M.roots[tab] = root
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
    local height = M.height or math.max(6, math.floor(vim.o.lines * 0.30))
    api.nvim_win_set_height(root, math.min(height, math.max(1, vim.o.lines - 6)))
    return root
  end
  local function geometry()
    local win = container()
    return {
      position = "float",
      relative = "win",
      win = win,
      row = 0,
      col = 0,
      width = function()
        return math.max(1, api.nvim_win_get_width(win) - 2)
      end,
      height = function()
        return math.max(1, api.nvim_win_get_height(win) - 2)
      end,
    }
  end
  local on_close = opts.win.on_close
  opts.override = false
  opts.win.keys = opts.win.keys or {}
  for _, direction in ipairs({ "h", "j", "k", "l" }) do
    opts.win.keys["nav_" .. direction] = {
      "<C-" .. direction .. ">",
      function()
        require("config.window_navigation").move(direction)
      end,
      mode = "t",
      desc = "切换到相邻区域",
    }
  end
  opts.win = vim.tbl_deep_extend("force", opts.win, geometry())
  opts.win.on_close = function(self)
    local closed_root = root
    root = nil
    if closed_root and api.nvim_win_is_valid(closed_root) then
      M.height = api.nvim_win_get_height(closed_root)
      if not M.switching then
        M.root = nil
        M.roots[tab] = nil
        pcall(api.nvim_win_close, closed_root, true)
        require("config.editor_card").refresh()
      end
    end
    if on_close then
      on_close(self)
    end
  end
  -- 启动宿主可能为日志捕获设置 NO_COLOR / TERM=dumb；交互终端需要真实色彩能力。
  local no_color = vim.env.NO_COLOR
  local old_term, old_colorterm = vim.env.TERM, vim.env.COLORTERM
  vim.env.NO_COLOR = nil
  vim.env.TERM, vim.env.COLORTERM = "xterm-256color", "truecolor"
  local ok, term = pcall(Snacks.terminal.open, cmd, opts)
  vim.env.NO_COLOR = no_color
  vim.env.TERM, vim.env.COLORTERM = old_term, old_colorterm
  if not ok then
    error(term)
  end
  local show = term.show
  term.show = function(self)
    self.opts = vim.tbl_deep_extend("force", self.opts, geometry())
    local result = show(self)
    if self.win then
      vim.w[self.win].terminal_card_source = root
    end
    return result
  end
  vim.w[term.win].terminal_card_source = root
  term:on({ "WinResized", "WinEnter" }, function(self)
    vim.schedule(function()
      if root and api.nvim_win_is_valid(root) and self:win_valid() then
        self:update()
        local islands = require("config.island_ui")
        if islands.apply then
          islands.apply()
        end
      end
    end)
  end)
  return term
end

return M
