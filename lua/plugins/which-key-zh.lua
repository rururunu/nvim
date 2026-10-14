-- 只翻译 which-key 弹窗中的文字，不重新定义快捷键。
local labels = {
  tabs = "标签页", code = "代码", debug = "调试", profiler = "性能分析",
  ["file/find"] = "文件/查找", git = "Git", hunks = "代码块",
  ["quit/session"] = "退出/会话", search = "搜索", ui = "界面",
  ["diagnostics/quickfix"] = "诊断/快速修复", prev = "上一个",
  next = "下一个", goto = "跳转", surround = "包围操作",
  fold = "折叠", buffer = "缓冲区", windows = "窗口",
  ["Open with system app"] = "用系统应用打开",
  ["Switch to Other Buffer"] = "切换到上一个缓冲区",
  ["Delete Buffer"] = "关闭缓冲区",
  ["Delete Other Buffers"] = "关闭其他缓冲区",
  ["Delete Buffer and Window"] = "关闭缓冲区和窗口",
  ["New File"] = "新建文件", ["Save File"] = "保存文件",
  ["Format"] = "格式化", ["Line Diagnostics"] = "当前行诊断",
  ["Location List"] = "位置列表", ["Quickfix List"] = "快速修复列表",
  ["Quit All"] = "全部退出", ["Terminal"] = "终端",
  ["Terminal (cwd)"] = "终端（当前目录）",
  ["Terminal (Root Dir)"] = "终端（项目根目录）",
  ["Split Window Below"] = "向下分屏", ["Split Window Right"] = "向右分屏",
  ["Delete Window"] = "关闭窗口", ["New Tab"] = "新建标签页",
  ["Close Tab"] = "关闭标签页", ["Close Other Tabs"] = "关闭其他标签页",
  ["First Tab"] = "第一个标签页", ["Last Tab"] = "最后一个标签页",
  ["Next Tab"] = "下一个标签页", ["Previous Tab"] = "上一个标签页",
  ["Git Blame Line"] = "查看当前行提交记录",
  ["Git Browse (open)"] = "在浏览器打开 Git 地址",
  ["Git Browse (copy)"] = "复制 Git 地址",
  ["Git Log"] = "Git 提交记录", ["Git Log (cwd)"] = "当前目录 Git 提交记录",
  ["Git Current File History"] = "当前文件 Git 历史",
  ["Lazygit (Root Dir)"] = "Lazygit（项目根目录）",
  ["Lazygit (cwd)"] = "Lazygit（当前目录）",
  ["Inspect Pos"] = "检查光标位置", ["Inspect Tree"] = "检查语法树",
  ["LazyVim Changelog"] = "LazyVim 更新日志",
}

return {
  "folke/which-key.nvim",
  opts = function(_, opts)
    opts.replace = opts.replace or {}
    opts.replace.desc = opts.replace.desc or {
      { "<Plug>%(?(.*)%)?", "%1" },
      { "^%+", "" },
      { "<[cC]md>", "" },
      { "<[cC][rR]>", "" },
      { "<[sS]ilent>", "" },
      { "^lua%s+", "" },
      { "^call%s+", "" },
      { "^:%s*", "" },
    }
    table.insert(opts.replace.desc, function(desc)
      return labels[desc] or desc
    end)
  end,
}
