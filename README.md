# Neovim

面向 Windows、从 VS Code 迁移的用户。基于 LazyVim，提供中文快捷键提示、项目与工作区恢复、文件标签、终端标签、Git、代码缩略图和 Java / Rust / Kotlin 开发工具。

## 快速安装

先准备 **Neovim 0.12+、Git、支持 Nerd Font 的终端**。代码搜索需要 `rg` 和 `fd`；Git 面板需要 LazyGit。语言开发环境按需安装。

在 PowerShell 中执行：

```powershell
git clone https://github.com/rururunu/nvim.git "$env:TEMP\nvim-config-setup"
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\nvim-config-setup\scripts\install.ps1" -InstallPlugins
nvim
```

安装脚本会备份原有的 `%LOCALAPPDATA%\nvim`，部署配置，再安装锁定的插件版本。首次运行需要联网；不会自动安装 JDK、Rust、数据库或启动业务服务。已有同名临时目录时，请更换克隆目录。

> 上述命令适用于**包含本安装脚本的仓库版本**。若远端尚未包含最新文件，先下载这份配置，在其根目录执行 `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -InstallPlugins`。

- [完整安装、升级与卸载](docs/installation.md)
- [日常操作手册](docs/usage.md)
- [开发环境与运行调试](docs/development.md)
- [故障排查](docs/troubleshooting.md)

## 第一次使用

1. 启动 `nvim`，等待插件安装完成；出现工具安装进度时等待结束。
2. 执行 `:DevHealth`，检查命令行工具；执行 `:checkhealth` 查看详细诊断。
3. 在终端进入项目目录，运行 `nvim`。之后可在启动页按 `p` 选择最近项目。
4. 按 `i` 输入，按 `Esc` 返回普通模式，`Ctrl+S` 保存。
5. 普通模式按空格查看中文快捷键，按 `F1` 打开工作台。

## 操作

完整教程见 **[详细操作手册](docs/usage.md)**，包含 20 个章节、逐步练习和实际操作示例。首次使用先看“第一次使用：完成一次编辑”；日常可通过目录按任务查阅。

### 常用操作速查

除特别注明外，快捷键在普通模式使用。`空格 q S` 中的 `S` 表示 `Shift+s`。

| 操作 | 快捷键 / 命令 |
| --- | --- |
| 查找文件 / 搜索内容 | `Ctrl+P` / `空格 /` |
| 文件树 / 切换项目 | `空格 e` / `空格 f p` |
| 切换已打开文件 | 点击顶部标签，或 `Shift+h/l` |
| 关闭当前文件 | `空格 b d` 或 `:bd` |
| 新建终端 / 隐藏终端面板 | `空格 t` / `F7` |
| 切换区域 / 调整大小 | `Ctrl+h/j/k/l` / `Ctrl+方向键` |
| Git 面板 | `空格 g g`，面板内 `q` 返回或退出 |
| 保存 / 恢复工作区 | `空格 q S` / `空格 q s` |
| 选择项目主题 | `空格 u P`，Enter 确认，Esc 取消 |
| 显示 / 隐藏代码缩略图 | `空格 u m` |
| 开关平滑光标 | `空格 u A` |
| 运行 / 构建 / 测试 | `空格 r r` |
| 保存或放弃修改后退出 | `:Exit` |

## 配置与数据在哪里

| 内容 | 默认位置 |
| --- | --- |
| 配置文件 | `%LOCALAPPDATA%\nvim` |
| 插件、Mason 工具及运行数据 | `%LOCALAPPDATA%\nvim-data` |
| 工作区、项目主题、配置备份 | Neovim 状态目录中的对应文件 / 子目录 |

以 Neovim 实际输出为准：`:lua print(vim.fn.stdpath('config'))`、`:lua print(vim.fn.stdpath('data'))`、`:lua print(vim.fn.stdpath('state'))`。设置了 `NVIM_APPNAME` 或 XDG 环境变量时，路径可能不同。

工作区记录保存文件列表与布局，不代替 `Ctrl+S`。重启后文件按磁盘内容读取；终端重新创建 shell，不恢复之前运行的进程。

## 修改配置

- 常用设置：`lua/config/options.lua`
- 快捷键：`lua/config/keymaps.lua`
- 添加或调整插件：`lua/plugins/`
- 开发者验证说明：[tests/README.md](tests/README.md)

修改前可执行 `:ConfigBackup`。当前没有启用 AI 插件。
