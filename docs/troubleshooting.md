# 故障排查

[返回首页](../README.md)

## 安装后没有加载这份配置

在 Neovim 执行：

```vim
:lua print(vim.fn.stdpath('config'))
:lua print(vim.fn.stdpath('data'))
:lua print(vim.fn.stdpath('state'))
```

确认配置目录里有 `init.lua` 和 `lua`。`nvim-data` 是运行数据目录，不是配置目录。如果设置过 `NVIM_APPNAME`、`XDG_CONFIG_HOME`，应使用实际路径；默认部署位置可能不适用。

## 插件下载失败、启动报缺少模块

1. 执行 `:Lazy`，查看失败插件的具体错误。
2. 确认 PowerShell 中 `git --version` 可运行，并能访问插件仓库。
3. 执行 `:Lazy restore` 重试锁定版本的安装。
4. 仍失败时记录完整错误，不要直接删除整个 `nvim-data`。

`-InstallPlugins` 只安装插件。JDK、Rust、数据库、语言工具的外部依赖仍要单独准备。

## 图标变成方框，缩略图显示异常

在 Windows Terminal 中选用已安装的 Nerd Font，重开终端。缩略图还需要字体支持 Braille 字符。终端的字体设置不会由 Neovim 自动修改。

## 搜索不到文件或内容

执行 `:DevHealth`，确认 `rg` 和 `fd` 可用。检查当前项目目录 `:pwd`，使用 `空格 f p` 重新选择项目。文件被 Git 忽略或搜索器过滤时，也可能不会出现在结果中。

## 没有补全、跳转或重命名

1. 在项目源码文件中执行 `:checkhealth vim.lsp`。
2. 用 `:Mason` 检查对应语言工具。
3. 检查项目是否完成依赖安装、JDK / 工具链是否符合要求。
4. Java 大项目首次索引需要等待；检查 `:LspLog`。
5. Kotlin 检查 JDK 21 启动配置，迁移电脑时不要沿用不存在的本机路径。

## 剪贴板无法与 Windows 互通

执行 `:checkhealth vim.provider`，检查 clipboard provider。先在输入模式用 `Ctrl+v` 粘贴测试；复制先用 `v` 选中，再按 `y` 或 `Ctrl+c`。

## 终端没有颜色

新建终端才会读取更新的环境。终端配置会在启动子进程时清除继承的 `NO_COLOR`，并声明彩色支持；但 `cmd` 的提示符和 `dir` 通常仍是单色。命令自身也需要输出 ANSI 颜色。

## 终端与编辑区操作混淆

- `F7`：隐藏 / 显示终端，不结束进程。
- `exit`：结束当前 shell。
- `Ctrl+k`：从底部终端返回上方编辑区。
- `Ctrl+j`：从编辑区进入下方终端。
- `Ctrl+方向键`：调整大小，不是移动焦点。
- 在终端普通模式下按 `i` 才会继续向 shell 输入。

## 关闭文件后不符合预期

使用 `空格 b d`，或在交互命令行中输入 `:bd`。配置会先选择其他文件再关闭旧缓冲区；不要用 `:q` 代替关闭文件标签。脚本里直接执行原生 `bdelete` 不经过交互命令重定向。

如果表现与手册不同，先重启 Neovim，确保旧进程没有继续使用修改前的配置。

## 工作区没有恢复

- 先确认当前项目目录，用 `空格 q S` 保存一次。
- 使用 `空格 q s` 手动恢复，或从项目列表重新进入。
- 已删除 / 移动的文件会跳过。
- 工作区不保存未写盘内容，也不保存终端进程状态。
- 工作区文件在 `stdpath('state')/workspaces`，按项目目录分别记录。

## 平滑光标拖影、输入感觉不跟手

按 `空格 u A` 关闭。永久关闭可以在 `lua/plugins/cursor-animation.lua` 中将 `smear-cursor.nvim` 的插件设置为 `enabled = false`，然后重启。终端字符动画与图形界面的光标动画不同。

## 数据库或 Markdown 浏览器预览不可用

数据库面板仍需你自己的连接和数据库客户端。Markdown 终端预览不需要浏览器；手动 `:MarkdownPreview` 的浏览器预览依赖其前端安装成功，执行 `:Lazy` 查看插件构建状态。

## 回退配置

- 编辑器中执行 `:ConfigRestore`，选择配置备份，重启。
- 或关闭 Neovim，将安装脚本生成的 `nvim.backup-*` 恢复成配置目录。
- 配置与插件版本需要一致时执行 `:Lazy restore`。

反馈问题时请提供：Neovim 版本、项目语言、复现按键、完整报错、`:DevHealth` 结果和截图。不要在日志中附带密钥或 secrets 文件内容。
