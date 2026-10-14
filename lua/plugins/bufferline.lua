return {
  "akinsho/bufferline.nvim",
  opts = {
    options = {
      always_show_bufferline = true,
      separator_style = "thin",
      indicator = { style = "icon", icon = "▎" },
      max_name_length = 30,
      tab_size = 30,
      show_close_icon = false,
      show_buffer_close_icons = false,
      modified_icon = "●",
      diagnostics = false,
      numbers = "none",
      offsets = {
        { filetype = "snacks_layout_box", text = "", separator = false },
        { filetype = "snacks_picker_list", text = "", separator = false },
        { filetype = "snacks_picker_input", text = "", separator = false },
      },
    },
    highlights = function(defaults)
      local function color(group, attr, fallback)
        return vim.api.nvim_get_hl(0, { name = group, link = false })[attr] or fallback
      end
      local bg = color("Normal", "bg", color("NormalFloat", "bg", 0x202020))
      local fg = color("Normal", "fg", 0xdddddd)
      local selected_bg = color("PmenuSel", "bg", color("Visual", "bg", bg))
      local selected_fg = color("PmenuSel", "fg", fg)
      local result = vim.deepcopy(defaults.highlights)
      for _, group in ipairs({ "background", "buffer_visible", "fill", "modified", "modified_visible" }) do
        result[group] = vim.tbl_extend("force", result[group] or {}, { bg = bg, italic = false })
      end
      for _, group in ipairs({ "buffer_selected", "modified_selected", "close_button_selected", "numbers_selected" }) do
        result[group] = vim.tbl_extend("force", result[group] or {}, { bg = selected_bg, fg = selected_fg, bold = true, italic = false })
      end
      result.indicator_selected = { fg = selected_fg, bg = selected_bg }
      return result
    end,
  },
}
