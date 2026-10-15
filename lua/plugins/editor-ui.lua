return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            title = "文件",
            config = function(opts)
              opts = require("snacks.picker.source.explorer").setup(opts)
              local root = vim.fs.normalize(opts.cwd or vim.fn.getcwd())
              opts.layout.wins = opts.layout.wins or {}
              opts.layout.wins.project_card = Snacks.win({
                text = { "   " .. vim.fs.basename(root), " " .. vim.fn.fnamemodify(root, ":~") },
                show = false, focusable = false,
                bo = { filetype = "project_card", buftype = "nofile" },
                wo = { winhighlight = "Normal:IslandSurface,NormalNC:IslandSurface,FloatBorder:IslandBorder", wrap = false },
              })
              opts.layout.layout[1].height = 2
              return opts
            end,
            prompt = " ",
            on_show = function(picker)
              picker.input.win:on("WinLeave", function()
                vim.schedule(function()
                  if not picker.closed and not picker.layout:is_hidden("input")
                    and vim.api.nvim_get_current_win() ~= picker.input.win.win then
                    picker.opts.actions.explorer_end_search(picker)
                  end
                end)
              end)
            end,
            icons = { tree = { vertical = "  ", middle = "├ ", last = "└ " } },
            actions = {
              explorer_windows = function(picker)
                local explorer = require("config.windows_explorer")
                explorer.open(explorer.selected(picker))
              end,
              explorer_context = function(picker)
                require("config.windows_explorer").context(picker)
              end,
              explorer_search = function(picker)
                picker:focus("input", { show = true })
              end,
              explorer_end_search = function(picker)
                picker.input:set("", "")
                picker:toggle("input", { enable = false, focus = "list" })
              end,
            },
            win = {
              list = {
                wo = { winhighlight = "Normal:IslandSurface,NormalNC:IslandSurface,FloatBorder:IslandBorder,FloatTitle:IslandTitle" },
                keys = {
                  ["/"] = "explorer_search",
                  ["<RightMouse>"] = "explorer_context",
                  ["gE"] = { "explorer_windows", desc = "在 Windows 资源管理器中显示" },
                },
              },
              input = { keys = {
                ["<Esc>"] = { "explorer_end_search", mode = { "n", "i" } },
              } },
            },
            layout = {
              preset = "sidebar",
              hidden = { "input" },
              layout = {
                box = "vertical",
                position = "left",
                height = 0,
                border = "rounded",
                backdrop = false,
                width = 48,
                min_width = 30,
                { win = "project_card", height = 2, border = "bottom" },
                { win = "input", height = 1, border = "rounded", title = " 搜索文件 ", title_pos = "left" },
                { win = "list", border = "none" },
              },
            },
          },
        },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options.globalstatus = true
      opts.options.disabled_filetypes = { statusline = {}, winbar = {} }
      opts.options.component_separators = { left = "", right = "" }
      opts.options.section_separators = { left = "", right = "" }
      opts.sections.lualine_a = {
        { "mode", fmt = function(mode)
          return ({ NORMAL = "普通", INSERT = "输入", VISUAL = "选择", ["V-LINE"] = "行选择",
            ["V-BLOCK"] = "块选择", COMMAND = "命令", REPLACE = "替换", TERMINAL = "终端" })[mode] or mode
        end },
      }
      opts.sections.lualine_b = { "branch" }
      opts.sections.lualine_c = {
        { "filename", path = 0, symbols = { modified = " ●", readonly = " ", unnamed = "未命名" } },
        { "diagnostics", sources = { "nvim_lsp" }, sections = { "error", "warn" },
          symbols = { error = " ", warn = " " } },
      }
      opts.sections.lualine_x = {
        { "diff", symbols = { added = "+", modified = "~", removed = "−" } },
        { "filetype", icon_only = false },
      }
      opts.sections.lualine_y = { "progress" }
      opts.sections.lualine_z = { "location" }
    end,
  },
  {
    "saghen/blink.cmp",
    opts = {
      completion = {
        menu = { border = "rounded" },
        documentation = { window = { border = "rounded" } },
      },
      signature = { window = { border = "rounded" } },
    },
  },
  { "folke/which-key.nvim", opts = { win = { border = "rounded" } } },
  {
    "folke/noice.nvim",
    opts = {
      views = {
        cmdline_popup = { border = { style = "rounded" } },
        popup = { border = { style = "rounded" } },
      },
    },
  },
}
