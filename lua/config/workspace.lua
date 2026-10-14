local M = {}
local api = vim.api
local function path(root)
  return vim.fn.stdpath("state") .. "/workspaces/" .. vim.fn.sha256(root:lower()) .. ".json"
end
function M.save()
  local root = vim.t.workspace_path or vim.fn.getcwd()
  local function capture(node)
    if node[1] == "leaf" then
      local win = node[2]
      local buf = api.nvim_win_get_buf(win)
      local file = api.nvim_buf_get_name(buf)
      if vim.bo[buf].buftype ~= "" or file == "" then
        return
      end
      return { kind = "file", file = file, view = api.nvim_win_call(win, vim.fn.winsaveview) }
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
      return { kind = node[1], children = children }
    end
  end
  local layout = capture(vim.fn.winlayout())
  if not layout then
    return false
  end
  vim.fn.mkdir(vim.fs.dirname(path(root)), "p")
  vim.fn.writefile({ vim.json.encode({ root = root, layout = layout }) }, path(root))
  return true
end
function M.restore()
  local root = vim.t.workspace_path or vim.fn.getcwd()
  if vim.fn.filereadable(path(root)) == 0 then
    vim.notify("当前项目还没有保存的工作区")
    return false
  end
  local ok, state = pcall(vim.json.decode, table.concat(vim.fn.readfile(path(root)), "\n"))
  if not ok or type(state.layout) ~= "table" then
    vim.notify("工作区记录损坏", vim.log.levels.ERROR)
    return false
  end
  -- 新标签页恢复，保留当前窗口和未保存内容。
  vim.cmd("tabnew")
  vim.t.workspace_path = root
  vim.cmd("tcd " .. vim.fn.fnameescape(root))
  local function build(node, win)
    api.nvim_set_current_win(win)
    if node.kind == "file" then
      if vim.fn.filereadable(node.file) == 1 then
        local buf = vim.fn.bufadd(node.file)
        vim.fn.bufload(buf)
        vim.bo[buf].buflisted = true
        api.nvim_win_set_buf(win, buf)
        vim.fn.winrestview(node.view or {})
      end
      return
    end
    local wins = { win }
    for _ = 2, #node.children do
      vim.cmd(node.kind == "row" and "rightbelow vnew" or "rightbelow new")
      wins[#wins + 1] = api.nvim_get_current_win()
    end
    for i, child in ipairs(node.children) do
      build(child, wins[i])
    end
  end
  build(state.layout, api.nvim_get_current_win())
  vim.cmd("wincmd =")
  return true
end
function M.setup()
  vim.t.workspace_path = vim.fn.getcwd()
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
