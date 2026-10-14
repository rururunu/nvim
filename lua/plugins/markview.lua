return {
  { "MeanderingProgrammer/render-markdown.nvim", enabled = false },
  {
    "OXY2DEV/markview.nvim",
    lazy = false,
    opts = {
      preview = { enable = false, modes = { "n", "no", "c", "i" }, hybrid_modes = {} },
      html = { container_elements = {
        ["^p$"] = { on_opening_tag = { conceal = "" }, on_closing_tag = { conceal = "" } },
        ["^div$"] = { on_opening_tag = { conceal = "" }, on_closing_tag = { conceal = "" } },
        ["^h[1-6]$"] = { on_opening_tag = { conceal = "" }, on_node = { hl_group = "Title" },
          on_closing_tag = { conceal = "" } },
      } },
    },
  },
}
