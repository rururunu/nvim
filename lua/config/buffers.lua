local M = {}
local api = vim.api

function M.close(force, requested)
  local buf = requested or api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(buf) then
    return
  end
  if vim.bo[buf].modified and not force then
    local choice =
      vim.fn.confirm("文件有未保存的修改，如何关闭？", "&保存后关闭\n&放弃修改\n&取消", 3)
    if choice == 0 or choice == 3 then
      return
    end
    if choice == 1 then
      local ok, err = pcall(api.nvim_buf_call, buf, function()
        vim.cmd.write()
      end)
      if not ok then
        vim.notify(tostring(err), vim.log.levels.ERROR)
        return
      end
    end
  end
  local candidates = vim.tbl_filter(function(info)
    return info.bufnr ~= buf and vim.bo[info.bufnr].buftype == ""
  end, vim.fn.getbufinfo({ buflisted = 1 }))
  table.sort(candidates, function(a, b)
    return a.lastused > b.lastused
  end)
  local replacement = candidates[1] and candidates[1].bufnr
  local windows = vim.fn.win_findbuf(buf)
  -- 先切换窗口中的文件，再删除旧缓冲区，避免 :bdelete 把编辑窗口一起关闭。
  for _, win in ipairs(windows) do
    if api.nvim_win_is_valid(win) then
      if replacement then
        api.nvim_win_set_buf(win, replacement)
      else
        local empty = api.nvim_create_buf(false, true)
        api.nvim_win_set_buf(win, empty)
      end
    end
  end
  api.nvim_buf_delete(buf, { force = true })
  require("config.editor_card").refresh()
  if not replacement and vim.bo.buftype == "nofile" then
    Snacks.dashboard()
  end
end

function M.setup()
  api.nvim_create_user_command("BufferClose", function(opts)
    M.close(opts.bang, opts.args ~= "" and vim.fn.bufnr(opts.args) or nil)
  end, { bang = true, nargs = "?", complete = "buffer", desc = "关闭文件并切换到其他文件" })
  -- 仅改写交互命令行中的独立命令，不影响脚本中的原生命令。
  for _, name in ipairs({ "bd", "bdelete" }) do
    vim.cmd.cnoreabbrev({
      args = {
        "<expr>",
        name,
        "getcmdtype() == ':' && trim(getcmdline()) == '" .. name .. "' ? 'BufferClose' : '" .. name .. "'",
      },
    })
  end
end

return M
