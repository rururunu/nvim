-- 在 LazyVim 设置初始配色时恢复当前项目保存的主题。
return {
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      opts.colorscheme = function()
        require("config.project_theme").startup_colorscheme()
      end
    end,
  },
  { "rebelot/kanagawa.nvim", lazy = true, opts = {} },
  { "ellisonleao/gruvbox.nvim", lazy = true, opts = {} },
  { "rose-pine/neovim", name = "rose-pine", lazy = true, opts = {} },
  { "EdenEast/nightfox.nvim", lazy = true, opts = {} },
  { "projekt0n/github-nvim-theme", lazy = true, opts = {} },
  { "sainnhe/everforest", lazy = true },
  { "shaunsingh/nord.nvim", lazy = true },
  { "Mofiqul/dracula.nvim", lazy = true, opts = {} },
  { "Mofiqul/vscode.nvim", lazy = true, opts = {} },
  { "nyoom-engineering/oxocarbon.nvim", lazy = true, build = false, pkg = false },
}
