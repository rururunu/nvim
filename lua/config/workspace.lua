local M = {}
local api = vim.api
local function path(root)
  return vim.fn.stdpath("state") .. "/workspaces/" .. vim.fn.sha256(root:lower()) .. ".json"
end
function M.exists(root)
  return vim.fn.filereadable(path(root or vim.t.workspace_path or vim.fn.getcwd())) == 1
end

function M.save()
  if M.restoring then
    return false
  end
  local root = vim.t.workspace_path or vim.fn.getcwd()
  local function capture(node)
    if node[1] == "leaf" then
      local win = node[2]
      local buf = api.nvim_win_get_buf(win)
      local file = api.nvim_buf_get_name(buf)
      if vim.bo[buf].buftype ~= "" or file == "" then
        return
      end
      return {
        kind = "file",
        file = file,
        view = api.nvim_win_call(win, vim.fn.winsaveview),
        width = api.nvim_win_get_width(win),
        height = api.nvim_win_get_height(win),
        active = win == api.nvim_get_current_win() or (vim.bo.buftype ~= "" and file == vim.t.workspace_active_file),
      }
    end
    local children = {}
    for _, child in ipairs(node[2]) do
      local saved = capture(child)
      if saved then
        children[#children + 1] = saved
      end
    end
    if #children == 1 then
      return children[1]
    end
    if #children > 0 then
      local width, height = 0, 0
      for _, child in ipairs(children) do
        width = node[1] == "row" and width + (child.width or 1) or math.max(width, child.width or 1)
        height = node[1] == "col" and height + (child.height or 1) or math.max(height, child.height or 1)
      end
      return { kind = node[1], children = children, width = width, height = height }
    end
  end
  local layout = capture(vim.fn.winlayout())
  if not layout then
    return false
  end
  vim.fn.mkdir(vim.fs.dirname(path(root)), "p")
  local buffers, seen = {}, {}
  local normalized = vim.fs.normalize(root):lower():gsub("/$", "") .. "/"
  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local file = api.nvim_buf_get_name(info.bufnr)
    if
      vim.bo[info.bufnr].buftype == ""
      and file ~= ""
      and vim.fs.normalize(file):lower():sub(1, #normalized) == normalized
    then
      if not seen[file] then
        buffers[#buffers + 1] = file
        seen[file] = true
      end
    end
  end
  local sidebar
  for _, picker in ipairs(Snacks.picker.get()) do
    if picker.opts.source == "explorer" and not picker.closed then
      sidebar = { width = picker.layout.root:win_valid() and api.nvim_win_get_width(picker.layout.root.win) or 48 }
      break
    end
  end
  local terminal = { height = require("config.docked_terminal").height, items = {} }
  local tabs = package.loaded["config.terminal_tabs"]
  if tabs then
    for _, item in ipairs(tabs.items) do
      if
        item.tab == api.nvim_get_current_tabpage()
        and item.term:buf_valid()
        and vim.fs.normalize(item.cwd):lower() == normalized:sub(1, -2)
      then
        terminal.items[#terminal.items + 1] = { cwd = item.cwd, active = item == tabs.current }
        if item.term:win_valid() then
          terminal.visible = true
          local container = vim.w[item.term.win].terminal_card_source
          if container and api.nvim_win_is_valid(container) then
            terminal.height = api.nvim_win_get_height(container)
          end
        end
      end
    end
  end
  local state = {
    version = 2,
    root = root,
    layout = layout,
    buffers = buffers,
    sidebar = sidebar,
    terminal = terminal,
    focus_terminal = vim.bo.filetype == "snacks_terminal",
  }
  local target = path(root)
  local temporary = target .. ".tmp"
  vim.fn.writefile({ vim.json.encode(state) }, temporary)
  assert((vim.uv or vim.loop).fs_rename(temporary, target))
  return true
end
function M.restore(opts)
  opts = opts or {}
  local root = vim.t.workspace_path or vim.fn.getcwd()
  if vim.fn.filereadable(path(root)) == 0 then
    if not opts.quiet then
      vim.notify("当前项目还没有保存的工作区")
    end
    return false
  end
  local ok, state = pcall(vim.json.decode, table.concat(vim.fn.readfile(path(root)), "\n"))
  if not ok or type(state.layout) ~= "table" then
    vim.notify("工作区记录损坏", vim.log.levels.ERROR)
    return false
  end
  -- 新标签页恢复，保留当前窗口和未保存内容。
  M.restoring = true
  local cards = require("config.editor_card")
  cards.suspended = true
  if opts.new_tab ~= false then
    vim.cmd("tabnew")
  end
  vim.t.workspace_path = root
  vim.cmd("tcd " .. vim.fn.fnameescape(root))
  for _, file in ipairs(state.buffers or {}) do
    if vim.fn.filereadable(file) == 1 then
      local buf = vim.fn.bufadd(file)
      vim.fn.bufload(buf)
      vim.bo[buf].buflisted = true
    end
  end
  local active
  local views = {}
  local function build(node, win)
    api.nvim_set_current_win(win)
    if node.kind == "file" then
      if vim.fn.filereadable(node.file) == 1 then
        local buf = vim.fn.bufadd(node.file)
        vim.fn.bufload(buf)
        vim.bo[buf].buflisted = true
        api.nvim_win_set_buf(win, buf)
        vim.fn.winrestview(node.view or {})
        views[win] = node.view or {}
        if node.active then
          active = win
        end
      end
      return
    end
    local wins = { win }
    for _ = 2, #node.children do
      vim.cmd(node.kind == "row" and "rightbelow vnew" or "rightbelow new")
      wins[#wins + 1] = api.nvim_get_current_win()
    end
    local dimension = node.kind == "row" and "width" or "height"
    local total, available = 0, node.kind == "row" and api.nvim_win_get_width(win) or api.nvim_win_get_height(win)
    for _, child in ipairs(node.children) do
      total = total + (child[dimension] or 1)
    end
    -- Set sibling proportions before building nested splits.
    local get = node.kind == "row" and api.nvim_win_get_width or api.nvim_win_get_height
    local set = node.kind == "row" and api.nvim_win_set_width or api.nvim_win_set_height
    available = 0
    for _, w in ipairs(wins) do
      available = available + get(w)
    end
    for i = 1, #wins - 1 do
      set(wins[i], math.max(1, math.floor(available * (node.children[i][dimension] or 1) / total)))
    end
    for i, child in ipairs(node.children) do
      build(child, wins[i])
    end
  end
  local built, err = xpcall(function()
    local editor = api.nvim_get_current_win()
    if state.sidebar then
      local picker = Snacks.explorer({ cwd = root, layout = { layout = { width = state.sidebar.width or 48 } } })
      vim.wait(500, function()
        return picker.closed or picker.layout.root:win_valid()
      end, 10)
    end
    api.nvim_set_current_win(editor)
    build(state.layout, editor)
  end, debug.traceback)
  cards.suspended = false
  M.restoring = false
  if not built then
    vim.notify(err, vim.log.levels.ERROR)
    return false
  end
  if active and api.nvim_win_is_valid(active) then
    api.nvim_set_current_win(active)
  end
  cards.refresh()
  local terminal = state.terminal
  if terminal and #(terminal.items or {}) > 0 then
    local dock = require("config.docked_terminal")
    dock.height = terminal.height
    local tabs = require("config.terminal_tabs")
    local chosen
    local reused = {}
    for _, saved in ipairs(terminal.items) do
      local exists
      for _, item in ipairs(tabs.items) do
        if
          item.tab == api.nvim_get_current_tabpage()
          and not reused[item]
          and item.term:buf_valid()
          and item.cwd == saved.cwd
        then
          exists = item
          break
        end
      end
      local item = exists or tabs.new()
      reused[item] = true
      if saved.active then
        chosen = item
      end
    end
    if chosen then
      tabs.show(chosen)
    end
    if not terminal.visible and tabs.current and tabs.current.term:win_valid() then
      tabs.toggle()
    end
  end
  for win, view in pairs(views) do
    if api.nvim_win_is_valid(win) then
      api.nvim_win_call(win, function()
        vim.fn.winrestview(view)
      end)
    end
  end
  if active and api.nvim_win_is_valid(active) and not state.focus_terminal then
    vim.cmd.stopinsert()
    api.nvim_set_current_win(active)
    local view = views[active]
    if view and view.lnum then
      api.nvim_win_set_cursor(active, { view.lnum, view.col or 0 })
    end
  end
  return true
end
function M.setup()
  vim.t.workspace_path = vim.fn.getcwd()
  api.nvim_create_autocmd("BufEnter", {
    group = api.nvim_create_augroup("workspace_active_file", { clear = true }),
    callback = function()
      if vim.bo.buftype == "" and api.nvim_buf_get_name(0) ~= "" then
        vim.t.workspace_active_file = api.nvim_buf_get_name(0)
      end
    end,
  })
  api.nvim_create_autocmd("TabEnter", {
    group = api.nvim_create_augroup("workspace_theme", { clear = true }),
    callback = function()
      local root = vim.t.workspace_path
      if root then
        require("config.project_theme").apply(root)
      end
    end,
  })
  api.nvim_create_autocmd("VimLeavePre", {
    group = api.nvim_create_augroup("workspace_save", { clear = true }),
    callback = function()
      pcall(M.save)
    end,
  })
  api.nvim_create_autocmd("TabLeave", {
    group = api.nvim_create_augroup("workspace_tab_save", { clear = true }),
    callback = function()
      pcall(M.save)
    end,
  })
end
return M
