-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 默认复制、删除和粘贴使用 Windows 系统剪贴板。
vim.opt.clipboard = "unnamedplus"
vim.opt.winborder = "rounded"
-- 单击切换编辑区、文件树和终端焦点；拖动仍用于选择或调整分屏。
vim.opt.mouse = "a"
vim.opt.mousefocus = false
-- Windows 的 SHELL 可能指向 PowerShell，但 Neovim 仍保留 cmd 的 /s /c 参数。
-- 统一 shell 参数，保证更多任务模板与 :! 命令同样可运行。
if
  vim.fn.has("win32") == 1
  and (vim.o.shell:lower():find("powershell", 1, true) or vim.o.shell:lower():find("pwsh", 1, true))
then
  vim.o.shellcmdflag = "-NoLogo -NoProfile -NonInteractive -Command "
    .. "[Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.UTF8Encoding]::new();"
    .. "$PSDefaultParameterValues['Out-File:Encoding']='utf8';"
  vim.o.shellquote, vim.o.shellxquote = "", ""
  vim.o.shellpipe, vim.o.shellredir = "> %s 2>&1", "> %s 2>&1"
  vim.o.shelltemp = false
end
-- winget 安装的便携命令：当前终端未刷新系统 PATH 时也可找到 LazyGit。
if vim.fn.has("win32") == 1 then
  local links = vim.env.LOCALAPPDATA .. "/Microsoft/WinGet/Links"
  if vim.fn.isdirectory(links) == 1 and not (vim.env.PATH or ""):lower():find(links:lower(), 1, true) then
    vim.env.PATH = vim.env.PATH .. ";" .. links
  end
  if vim.fn.executable("lazygit") == 0 then
    local executables =
      vim.fn.glob(vim.env.LOCALAPPDATA .. "/Microsoft/WinGet/Packages/JesseDuffield.lazygit_*/lazygit.exe", false, true)
    if executables[1] then
      vim.env.PATH = vim.env.PATH .. ";" .. vim.fs.dirname(executables[1])
    end
  end
end

-- Python LSP: 使用 basedpyright（支持 inlay hints）代替 pyright
vim.g.lazyvim_python_lsp = "basedpyright"

-- 默认关闭 inlay hints，可用 <leader>uh 切换
-- vim.g.lazyvim_inlay_hints = false

-- 全局禁用拼写检查（默认关闭，可用快捷键切换）
vim.opt.spell = false

-- 1. 禁用注释自动延续（按回车后下一行不自动继承注释）
vim.opt.formatoptions:remove("c")
vim.opt.formatoptions:remove("r")
vim.opt.formatoptions:remove("o")

-- 2. 允许左右方向键换行
vim.opt.whichwrap:append("<,>,h,l")

-- 3. 默认关闭自动换行，长行通过水平滚动查看。
vim.opt.wrap = false

-- 光标离上下边框最少1行，改成0就是完全贴边
vim.opt.scrolloff = 2

-- 更接近常见编辑器的行号；状态栏不展开冗长的方法签名。
vim.opt.relativenumber = false
vim.g.trouble_lualine = false

-- Windows 上 Tree-sitter 编译解析器需要 C 编译器；使用已安装的 LLVM。
if vim.fn.has("win32") == 1 and vim.fn.executable("clang") == 0 then
  local llvm_bin = "C:/Program Files/LLVM/bin"
  if vim.fn.filereadable(llvm_bin .. "/clang.exe") == 1 then
    vim.env.PATH = vim.env.PATH .. ";" .. llvm_bin
  end
end
