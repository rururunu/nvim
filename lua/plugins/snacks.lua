return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    picker = {
      sources = {
        files = {
          hidden = true, -- 显示隐藏文件
        },
      },
    },
    dashboard = {
      enabled = true,
      width = 64,
      pane_gap = 8,
      preset = {
        header = [[
NEOVIM
继续你的工作
]],
        keys = {
          { icon = " ", key = "p", desc = "所有项目", action = function()
            require("config.recent_projects").open_picker()
          end },
          { icon = " ", key = "f", desc = "查找文件", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "g", desc = "搜索内容", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "n", desc = "新建文件", action = ":ene | startinsert" },
          { icon = " ", key = "r", desc = "最近文件", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "s", desc = "恢复当前项目工作区", action = function()
            require("config.workspace").restore()
          end },
          { icon = "󰏘 ", key = "t", desc = "选择当前项目主题", action = function()
            require("config.project_theme").pick()
          end },
          { icon = " ", key = "h", desc = "中文入门指南", action = function()
            vim.cmd.edit(vim.fn.fnameescape(vim.fn.stdpath("config") .. "/README.md"))
          end },
          { icon = " ", key = "q", desc = "保存或放弃修改后退出", action = function()
            require("config.exit").pick()
          end },
        },
      },
      sections = {
        { section = "header", padding = 1 },
        { text = "选择一项并回车，也可按右侧快捷键", align = "center", padding = 1 },
        {
          icon = " ", title = "最近项目 · p 查看全部", indent = 2, padding = 1,
          function()
            return require("config.dashboard_content").projects()
          end,
        },
        { icon = " ", title = "最近文件 · r 查看全部", indent = 2, padding = 1,
          function() return require("config.dashboard_content").files() end },
        { pane = 2, header = "常用操作", padding = 2 },
        { pane = 2, section = "keys", indent = 2, gap = 1, padding = 1 },
      },
    },
    image = {
      enabled = true,
      formats = {
        "png",
        "jpg",
        "jpeg",
        "gif",
        "bmp",
        "webp",
        "svg",
        "ico",
        "avif",
        "cur",
        "tiff",
        "tif",
        "ppm",
        "pgm",
        "pbm",
        "apng",
        "pdf",
      },
      convert = {
        magick = {
          pdf = {
            "-density",
            "192",
            "{src}[{page}]",
            "-background",
            "white",
            "-alpha",
            "remove",
            "-trim",
          },
        },
      },
      doc = {
        enabled = true,
        inline = true,
        float = true,
      },
    },

    terminal = {
      enabled = true,
      override = function(cmd, opts) return require("config.docked_terminal").open(cmd, opts) end,
      win = {
        style = "terminal",
        position = "float",
        relative = "win",
        border = "rounded",
        backdrop = false,
        row = 0,
        col = 0,
        title = " 终端 ",
        title_pos = "left",
        wo = { winhighlight = "Normal:IslandSurface,NormalNC:IslandSurface,FloatBorder:IslandBorder,FloatTitle:IslandTitle" },
      },
    },
  },
  keys = {
    -- 终端共用底部区域，每次创建新的标签。
    {
      "<leader>t",
      function()
        require("config.terminal_tabs").new()
      end,
      desc = "新建终端标签",
    },
    { "<F7>", function() require("config.terminal_tabs").toggle() end, desc = "显示/隐藏终端面板", mode = { "n", "t" } },
    { "<leader>T", function() require("config.terminal_tabs").pick() end, desc = "选择终端标签" },
  },
  -- 设置 Dashboard 自定义颜色
  config = function(_, opts)
    -- 先初始化 snacks
    require("snacks").setup(opts)

    local function highlights()
      for group, link in pairs({ Header = "Title", Icon = "Directory", Desc = "Normal", Key = "Special", Dir = "Comment", File = "Normal" }) do
        vim.api.nvim_set_hl(0, "SnacksDashboard" .. group, { link = link })
      end
    end
    highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("dashboard_theme", { clear = true }),
      callback = highlights,
    })
  end,
}
