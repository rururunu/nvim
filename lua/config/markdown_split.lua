local M = { pairs = {}, busy = false, disabled = {} }
local api = vim.api
local function valid(win) return win and api.nvim_win_is_valid(win) end

function M.close(tab)
  local pair = M.pairs[tab]
  M.pairs[tab] = nil
  if not pair then return end
  for _, win in ipairs({ pair.preview, pair.root }) do
    if valid(win) then pcall(api.nvim_win_close, win, true) end
  end
end

function M.update(pair)
  if not valid(pair.preview) or not valid(pair.root) or not api.nvim_buf_is_valid(pair.source)
    or not api.nvim_buf_is_valid(pair.buf) then return end
  vim.bo[pair.buf].modifiable = true
  api.nvim_buf_set_lines(pair.buf, 0, -1, false, api.nvim_buf_get_lines(pair.source, 0, -1, false))
  vim.bo[pair.buf].modifiable = false
  api.nvim_win_set_config(pair.preview, { relative = "win", win = pair.root, row = 0, col = 0,
    width = math.max(1, api.nvim_win_get_width(pair.root) - 2),
    height = math.max(1, api.nvim_win_get_height(pair.root) - 2) })
  local actions = require("markview.actions")
  actions.set_query(pair.buf)
  api.nvim_win_call(pair.preview, function()
    actions.render(pair.buf, { enable = true, hybrid_mode = false })
    vim.wo.conceallevel = 3
    vim.wo.concealcursor = "nvic"
  end)
  if valid(pair.sourcewin) then
    local view = api.nvim_win_call(pair.sourcewin, vim.fn.winsaveview)
    api.nvim_win_call(pair.preview, function()
      vim.fn.winrestview({ topline = view.topline, lnum = view.lnum, col = 0 })
    end)
  end
end

function M.open()
  if M.busy or vim.bo.filetype ~= "markdown" or vim.bo.buftype ~= "" then return end
  local tab, sourcewin, source = api.nvim_get_current_tabpage(), api.nvim_get_current_win(), api.nvim_get_current_buf()
  if M.disabled[source] then return end
  local old = M.pairs[tab]
  if old and old.source == source and valid(old.preview) then return end
  M.busy = true
  M.close(tab)
  require("markview.actions").disable(source)
  vim.wo[sourcewin].conceallevel = 0
  local anchor = vim.w[sourcewin].editor_card_source or sourcewin
  api.nvim_set_current_win(anchor)
  vim.cmd("rightbelow vnew")
  local root = api.nvim_get_current_win()
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.filetype = "markdown_preview_container"
  vim.bo.buflisted = false
  vim.wo.winbar = ""
  local buf = api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.b[buf].markdown_preview = true
  vim.bo[buf].filetype = "markdown"
  -- 预览是 nofile 缓冲区，不会自动启动 Tree-sitter；没有高亮附加就无法隐藏源码标记。
  vim.treesitter.start(buf, "markdown")
  local preview = api.nvim_open_win(buf, false, { relative = "win", win = root, row = 0, col = 0,
    width = math.max(1, api.nvim_win_get_width(root) - 2), height = math.max(1, api.nvim_win_get_height(root) - 2),
    border = "rounded", title = " Markdown 预览 ", title_pos = "left", zindex = 35 })
  vim.wo[preview].winhighlight = "Normal:IslandSurface,NormalNC:IslandSurface,FloatBorder:IslandBorder,FloatTitle:IslandTitle"
  vim.wo[preview].number = false
  vim.wo[preview].relativenumber = false
  vim.wo[preview].signcolumn = "no"
  vim.wo[preview].conceallevel = 3
  vim.wo[preview].concealcursor = "nvic"
  vim.wo[preview].wrap = true
  vim.wo[preview].cursorline = false
  local pair = { source = source, sourcewin = sourcewin, root = root, preview = preview, buf = buf }
  M.pairs[tab] = pair
  M.update(pair)
  api.nvim_set_current_win(sourcewin)
  require("config.editor_card").refresh()
  M.busy = false
end

function M.setup()
  local group = api.nvim_create_augroup("markdown_split", { clear = true })
  api.nvim_create_autocmd({ "BufEnter", "FileType" }, { group = group, callback = function()
    vim.schedule(function()
      local pair = M.pairs[api.nvim_get_current_tabpage()]
      if pair and valid(pair.sourcewin) and api.nvim_win_get_buf(pair.sourcewin) ~= pair.source then
        M.close(api.nvim_get_current_tabpage())
      end
      M.open()
    end)
  end })
  api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost", "WinResized" }, {
    group = group, callback = function()
      vim.schedule(function() for _, pair in pairs(M.pairs) do M.update(pair) end end)
    end,
  })
  api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinScrolled" }, {
    group = group, callback = function()
      local pair = M.pairs[api.nvim_get_current_tabpage()]
      if pair and api.nvim_get_current_win() == pair.sourcewin then
        vim.schedule(function()
          if valid(pair.preview) and valid(pair.sourcewin) then
            local view = api.nvim_win_call(pair.sourcewin, vim.fn.winsaveview)
            api.nvim_win_call(pair.preview, function()
              vim.fn.winrestview({ topline = view.topline, lnum = view.lnum, col = 0 })
            end)
          end
        end)
      end
    end,
  })
  api.nvim_create_autocmd("WinClosed", { group = group, callback = function(args)
    local closed = tonumber(args.match)
    for tab, pair in pairs(M.pairs) do
      if closed == pair.preview or closed == pair.root or closed == pair.sourcewin then
        vim.schedule(function() if M.pairs[tab] == pair then M.close(tab) end end)
      end
    end
  end })
  api.nvim_create_user_command("MarkdownSplit", function()
    M.disabled[api.nvim_get_current_buf()] = nil
    M.open()
  end, { desc = "打开右侧 Markdown 渲染预览" })
  api.nvim_create_user_command("MarkdownSplitClose", function()
    local tab = api.nvim_get_current_tabpage()
    local pair = M.pairs[tab]
    if pair then M.disabled[pair.source] = true end
    M.close(tab)
  end,
    { desc = "关闭 Markdown 分屏预览" })
  vim.schedule(M.open)
end

return M
