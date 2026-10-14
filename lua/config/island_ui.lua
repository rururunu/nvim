local M = {}

function M.setup()
  local separators = { vert = " ", horiz = " ", vertleft = " ", vertright = " ", verthoriz = " ", horizup = " ", horizdown = " " }
  vim.opt.fillchars:append(separators)
  local function clear_separators()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
      if vim.w[win].editor_card_source or vim.b[vim.api.nvim_win_get_buf(win)].markdown_preview
        or ft == "markdown_preview_container" or ft == "editor_card_container" or ft == "terminal_card_container"
        or ft == "snacks_terminal" or ft == "snacks_layout_box" or ft == "project_card"
        or ft == "snacks_picker_list" or ft == "snacks_picker_input" then
        local highlights = {}
        for from, to in vim.wo[win].winhighlight:gmatch("([^,:]+):([^,]+)") do highlights[from] = to end
        for _, name in ipairs({ "Normal", "NormalNC", "NormalFloat", "EndOfBuffer", "SignColumn" }) do
          highlights[name] = "IslandSurface"
        end
        highlights.FloatBorder = "IslandBorder"
        highlights.FloatTitle = "IslandTitle"
        local result = {}
        for from, to in pairs(highlights) do result[#result + 1] = from .. ":" .. to end
        vim.wo[win].winhighlight = table.concat(result, ",")
        vim.wo[win].winblend = 0
      end
      if vim.api.nvim_win_get_config(win).relative == "" then
        -- Snacks 的容器有独立的窗口选项，需要同时清理局部分隔符。
        vim.api.nvim_win_call(win, function()
          local chars = vim.opt_local.fillchars:get()
          for key, value in pairs(separators) do chars[key] = value end
          vim.opt_local.fillchars = chars
        end)
      end
    end
  end
  M.apply = clear_separators
  local function refresh()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    local border = vim.api.nvim_get_hl(0, { name = "FloatBorder", link = false })
    local title = vim.api.nvim_get_hl(0, { name = "Title", link = false })
    vim.api.nvim_set_hl(0, "IslandSurface", { fg = normal.fg, bg = normal.bg })
    vim.api.nvim_set_hl(0, "IslandBorder", { fg = border.fg, bg = normal.bg })
    vim.api.nvim_set_hl(0, "IslandTitle", { fg = title.fg or normal.fg, bg = normal.bg, bold = true })
    -- 空白分隔字符仍可能带有主题的背景色，统一为工作区底色。
    vim.api.nvim_set_hl(0, "WinSeparator", { fg = normal.bg, bg = normal.bg })
    vim.schedule(clear_separators)
  end
  refresh()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("island_ui", { clear = true }),
    callback = refresh,
  })
  vim.api.nvim_create_autocmd({ "WinNew", "WinEnter", "WinResized", "VimResized" }, {
    group = vim.api.nvim_create_augroup("island_separators", { clear = true }),
    callback = function() vim.schedule(clear_separators) end,
  })
  clear_separators()
end

return M
