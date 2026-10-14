return {
  "saghen/blink.cmp",
  opts = function(_, opts)
    opts.cmdline = opts.cmdline or {}
    opts.cmdline.keymap = opts.cmdline.keymap or {}
    opts.cmdline.keymap["<Down>"] = { "select_next", "fallback" }
    opts.cmdline.keymap["<Up>"] = { "select_prev", "fallback" }
    opts.sources = opts.sources or {}
    opts.sources.providers = opts.sources.providers or {}
    opts.sources.providers.cmdline = opts.sources.providers.cmdline or {}
    local provider = opts.sources.providers.cmdline
    local previous = provider.transform_items
    provider.transform_items = function(ctx, items)
      if previous then
        items = previous(ctx, items)
      end
      local commands = ctx.mode == "cmdline" and vim.fn.getcmdtype() == ":"
        and vim.fn.getcmdcompltype() == "command"
      return require("config.command_descriptions").annotate(items, commands)
    end
  end,
}
