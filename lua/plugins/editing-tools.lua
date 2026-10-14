return {
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    opts = {},
    keys = {
      { "<leader>cr", function() return ":IncRename " .. vim.fn.expand("<cword>") end,
        expr = true, desc = "重命名符号（实时预览）" },
    },
  },
  {
    "Wansmer/treesj",
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    opts = { use_default_keymaps = false },
    keys = {
      { "<leader>cj", "<cmd>TSJToggle<cr>", desc = "切换代码单行 / 多行" },
    },
  },
  {
    "chrisgrieser/nvim-spider",
    keys = {
      { "w", function() require("spider").motion("w") end, mode = { "n", "x", "o" }, desc = "下一个子单词" },
      { "e", function() require("spider").motion("e") end, mode = { "n", "x", "o" }, desc = "子单词末尾" },
      { "b", function() require("spider").motion("b") end, mode = { "n", "x", "o" }, desc = "上一个子单词" },
    },
  },
  {
    "abecodes/tabout.nvim",
    event = "InsertEnter",
    opts = { tabkey = "", backwards_tabkey = "", completion = false },
  },
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      local function tabout(backwards)
        return function()
          if not vim.treesitter.get_parser(0, nil, { error = false }) then return end
          require("tabout")
          local key = backwards and "<Plug>(TaboutBack)" or "<Plug>(Tabout)"
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "m", false)
          return true
        end
      end
      opts.keymap = opts.keymap or {}
      opts.keymap["<Tab>"] = { "snippet_forward", "select_next", tabout(false), "fallback" }
      opts.keymap["<S-Tab>"] = { "snippet_backward", "select_prev", tabout(true), "fallback" }
    end,
  },
  {
    "mbbill/undotree",
    cmd = { "UndotreeToggle", "UndotreeShow" },
    keys = { { "<leader>su", "<cmd>UndotreeToggle<cr>", desc = "撤销历史树" } },
    init = function()
      vim.g.undotree_SetFocusWhenToggle = 1
      local diff = "C:/Program Files/Git/usr/bin/diff.exe"
      if vim.fn.executable("diff") == 0 and vim.fn.executable(diff) == 1 then
        vim.g.undotree_DiffCommand = vim.fn.fnamemodify(diff, ":8")
      end
    end,
  },
  {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = { default_mappings = false, excluded_filetypes = { "snacks_dashboard", "snacks_terminal", "snacks_picker_list" } },
    keys = {
      { "<leader>ma", function() require("marks").set_next() end, desc = "添加位置标记" },
      { "<leader>md", function() require("marks").delete_line() end, desc = "删除本行标记" },
      { "<leader>mn", function() require("marks").next() end, desc = "下一个标记" },
      { "<leader>mp", function() require("marks").prev() end, desc = "上一个标记" },
      { "<leader>ml", function() Snacks.picker.marks() end, desc = "查看位置标记" },
    },
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    dependencies = { { "tpope/vim-dadbod", cmd = "DB" }, {
      "kristijanhusak/vim-dadbod-completion",
      init = function()
        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("database_completion", { clear = true }),
          pattern = { "sql", "mysql", "plsql" },
          callback = function() vim.bo.omnifunc = "vim_dadbod_completion#omni" end,
        })
      end,
    } },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
    end,
    keys = { { "<leader>D", "<cmd>DBUIToggle<cr>", desc = "数据库面板" } },
  },
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    opts = { default_file_explorer = false, float = { border = "rounded" }, view_options = { show_hidden = true } },
    keys = { { "<leader>fo", "<cmd>Oil --float<cr>", desc = "文件批量管理（Oil）" } },
  },
  {
    "chrisgrieser/nvim-various-textobjs",
    opts = { keymaps = { useDefaults = false } },
    keys = {
      { "iI", function() require("various-textobjs").indentation("inner", "inner") end, mode = { "o", "x" }, desc = "选中缩进块内部" },
      { "aI", function() require("various-textobjs").indentation("outer", "outer") end, mode = { "o", "x" }, desc = "选中整个缩进块" },
    },
  },
  { "folke/which-key.nvim", opts = { spec = { { "<leader>m", group = "位置标记" } } } },
}
