local M = { cards = {} }
local api = vim.api
local busy = false

local function close(win)
  if win and api.nvim_win_is_valid(win) then
    pcall(api.nvim_win_close, win, true)
  end
end

local function scratch(ft)
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = ft
  return buf
end

local function bar(source, above, height)
  local previous = api.nvim_get_current_win()
  api.nvim_set_current_win(source)
  vim.cmd((above and "aboveleft " or "belowright ") .. height .. "new")
  local win = api.nvim_get_current_win()
  local unused = api.nvim_win_get_buf(win)
  api.nvim_win_set_buf(win, scratch("editor_card_bar"))
  pcall(api.nvim_buf_delete, unused, { force = true })
  vim.w[win].editor_bar_source = source
  vim.wo[win].winfixheight = true
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].statuscolumn = ""
  vim.wo[win].winbar = ""
  vim.wo[win].cursorline = false
  vim.wo[win].wrap = false
  vim.wo[win].winhighlight = "Normal:IslandSurface,NormalNC:IslandSurface,EndOfBuffer:IslandSurface"
  if api.nvim_win_is_valid(previous) then
    api.nvim_set_current_win(previous)
  end
  return win
end

local ns = api.nvim_create_namespace("editor_card_tabs")
local function render(source, card)
  local width = api.nvim_win_get_width(source)
  local active = api.nvim_get_current_win() == source or vim.w.editor_bar_source == source
  local border = active and "IslandBorderActive" or "IslandBorder"
  local line = "╭" .. string.rep("─", math.max(0, width - 2)) .. "╮"
  local labels, ranges, columns = "│ ", {}, 2
  local selected = api.nvim_win_get_buf(source)
  card.tabs = {}
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
      local name = vim.fs.basename(api.nvim_buf_get_name(buf))
      if name == "" then
        name = "未命名"
      end
      local icon = ""
      local icons_ok, icons = pcall(require, "mini.icons")
      if icons_ok then
        icon = icons.get("file", api.nvim_buf_get_name(buf))
      end
      local text = (buf == selected and " ▎ " or "   ")
        .. icon
        .. " "
        .. vim.fn.strcharpart(name, 0, 24)
        .. (vim.bo[buf].modified and " ● " or "  ")
      local size = vim.fn.strdisplaywidth(text)
      if columns + size > width - 2 then
        break
      end
      local start = #labels
      labels = labels .. text
      ranges[#ranges + 1] = { start, #labels, buf == selected and "IslandTabActive" or "IslandTab" }
      card.tabs[#card.tabs + 1] = { first = columns + 1, last = columns + size, buf = buf }
      columns = columns + size
    end
  end
  labels = labels .. string.rep(" ", math.max(0, width - columns - 1)) .. "│"
  local hb = api.nvim_win_get_buf(card.header)
  api.nvim_win_set_hl_ns(card.header, 0)
  api.nvim_win_set_hl_ns(card.footer, 0)
  api.nvim_buf_set_lines(hb, 0, -1, false, { line, labels })
  api.nvim_buf_clear_namespace(hb, ns, 0, -1)
  api.nvim_buf_set_extmark(hb, ns, 0, 0, { end_col = #line, hl_group = border, priority = 10000 })
  for _, r in ipairs(ranges) do
    api.nvim_buf_set_extmark(hb, ns, 1, r[1], { end_col = r[2], hl_group = r[3], priority = 10000 })
  end
  local fb = api.nvim_win_get_buf(card.footer)
  local bottom = "╰" .. string.rep("─", math.max(0, width - 2)) .. "╯"
  api.nvim_buf_set_lines(fb, 0, -1, false, { bottom })
  api.nvim_buf_clear_namespace(fb, ns, 0, -1)
  api.nvim_buf_set_extmark(fb, ns, 0, 0, { end_col = #bottom, hl_group = border, priority = 10000 })
  for index, col in ipairs({ 0, math.max(0, width - 1) }) do
    local side = card.sides[index]
    local top = api.nvim_win_get_position(card.header)
    local bottom = api.nvim_win_get_position(card.footer)
    local height = math.max(1, bottom[1] - top[1] - 1)
    local config = {
      relative = "editor",
      row = top[1] + 1,
      col = top[2] + col,
      width = 1,
      height = height,
      border = "none",
      focusable = false,
      mouse = false,
      style = "minimal",
      zindex = 2,
      noautocmd = true,
    }
    if not side or not api.nvim_win_is_valid(side) then
      side = api.nvim_open_win(scratch("editor_card_edge"), false, config)
      card.sides[index] = side
    else
      api.nvim_win_set_config(side, config)
    end
    local lines = {}
    for _ = 1, height do
      lines[#lines + 1] = "│"
    end
    api.nvim_buf_set_lines(api.nvim_win_get_buf(side), 0, -1, false, lines)
    api.nvim_win_set_hl_ns(side, 0)
    vim.wo[side].winhighlight = "Normal:" .. border .. ",NormalFloat:" .. border
    vim.wo[side].winblend = 0
  end
end

function M.clear()
  for source, card in pairs(M.cards) do
    for _, side in ipairs(card.sides) do
      close(side)
    end
    close(card.header)
    close(card.footer)
    M.cards[source] = nil
  end
end

function M.refresh()
  if M.suspended or busy or vim.v.exiting ~= vim.NIL and vim.v.exiting ~= nil then
    return
  end
  busy = true
  local islands = require("config.island_ui")
  if islands.ensure_highlights then
    islands.ensure_highlights()
  end
  for source, card in pairs(M.cards) do
    if
      not api.nvim_win_is_valid(source)
      or vim.bo[api.nvim_win_get_buf(source)].buftype ~= ""
      or not api.nvim_win_is_valid(card.header)
      or not api.nvim_win_is_valid(card.footer)
    then
      for _, side in ipairs(card.sides) do
        close(side)
      end
      close(card.header)
      close(card.footer)
      M.cards[source] = nil
    end
  end
  local sources = {}
  for _, source in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_config(source).relative == "" and vim.bo[api.nvim_win_get_buf(source)].buftype == "" then
      sources[#sources + 1] = source
    end
  end
  for _, source in ipairs(sources) do
    vim.wo[source].winbar = ""
    vim.wo[source].sidescrolloff = math.max(1, vim.wo[source].sidescrolloff)
    local card = M.cards[source]
    if not card then
      card = { sides = {} }
      M.cards[source] = card
      card.header = bar(source, true, 2)
      card.footer = bar(source, false, 1)
    end
    if api.nvim_win_get_height(card.header) ~= 2 then
      api.nvim_win_set_height(card.header, 2)
    end
    if api.nvim_win_get_height(card.footer) ~= 1 then
      api.nvim_win_set_height(card.footer, 1)
    end
    render(source, card)
  end
  busy = false
end

function M.setup()
  vim.opt.showtabline = 0
  -- 鼠标按下时仍处于原窗口，必须在全局拦截，不能只映射标签栏缓冲区。
  local tab_press = false
  for _, key in ipairs({ "<LeftMouse>", "<2-LeftMouse>", "<3-LeftMouse>", "<4-LeftMouse>" }) do
    vim.keymap.set({ "n", "i", "x", "t" }, key, function()
      local pos = vim.fn.getmousepos()
      for source, card in pairs(M.cards) do
        if pos.winid == card.header then
          tab_press = true
          local selected
          if pos.line == 2 then
            for _, tab in ipairs(card.tabs or {}) do
              if pos.column >= tab.first and pos.column <= tab.last then
                selected = tab.buf
                break
              end
            end
          end
          vim.schedule(function()
            if not api.nvim_win_is_valid(source) then
              return
            end
            vim.cmd.stopinsert()
            if selected and api.nvim_buf_is_valid(selected) then
              api.nvim_win_set_buf(source, selected)
            end
            api.nvim_set_current_win(source)
            M.refresh()
          end)
          return "<Ignore>"
        end
      end
      tab_press = false
      return key
    end, { expr = true, desc = "点击文件标签或切换区域" })
  end
  for _, key in ipairs({ "<LeftDrag>", "<LeftRelease>" }) do
    vim.keymap.set({ "n", "i", "x", "t" }, key, function()
      local consume = tab_press
      if key == "<LeftRelease>" then
        tab_press = false
      end
      return consume and "<Ignore>" or key
    end, { expr = true })
  end
  for key, command in pairs({ ["<S-h>"] = "bprevious", ["<S-l>"] = "bnext", ["[b"] = "bprevious", ["]b"] = "bnext" }) do
    vim.keymap.set(
      "n",
      key,
      "<cmd>" .. command .. "<cr>",
      { desc = command == "bnext" and "下一个缓冲区" or "上一个缓冲区" }
    )
  end
  local pending = false
  api.nvim_create_autocmd({
    "WinEnter",
    "WinClosed",
    "WinResized",
    "VimResized",
    "BufWinEnter",
    "TabEnter",
    "ColorScheme",
    "BufModifiedSet",
    "BufFilePost",
    "BufAdd",
    "BufDelete",
  }, {
    group = api.nvim_create_augroup("editor_card", { clear = true }),
    callback = function()
      if busy or pending then
        return
      end
      pending = true
      vim.schedule(function()
        pending = false
        M.refresh()
      end)
    end,
  })
  M.refresh()
end
return M
