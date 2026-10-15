# 安装、升级与卸载

[返回首页](../README.md)

## 1. 准备 Windows 环境

在 Windows Terminal 中打开 PowerShell。安装下面的软件，并在安装后重新打开终端。

| 依赖 | 用途 | 是否必须 |
| --- | --- | --- |
| Neovim 0.12 或更新版本 | 运行编辑器 | 必须 |
| Git | 下载配置和插件 | 必须 |
| Nerd Font 字体 | 文件、文件夹、终端等图标 | 推荐 |
| ripgrep（`rg`） | 搜索项目内容 | 搜索功能需要 |
| fd | 快速查找文件 | 推荐 |
| LazyGit | Git 交互面板 | 使用 Git 面板时需要 |
| Node.js、Python、编译器 | 部分语言工具和插件安装 | 按工具需求安装 |

可通过 Windows 包管理器搜索并安装，例如：

```powershell
winget search Neovim
winget search Git.Git
winget search ripgrep
winget search sharkdp.fd
winget search lazygit
```

从结果中确认软件 ID 后使用 `winget install --id <软件ID> --exact`。字体安装后，还要在 Windows Terminal 的“设置 → 配置文件 → 外观 → 字体”中选用它，例如已安装的 Cascadia Code Nerd Font。不要只安装字体却不切换终端字体。

检查命令是否可用：

```powershell
nvim --version
git --version
rg --version
fd --version
lazygit --version
```

## 2. 一键部署配置

先关闭已打开的 Neovim。下载或克隆配置，进入配置仓库目录后执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -InstallPlugins
```

脚本执行以下操作：

1. 检查配置源目录。
2. 将已有目标配置移动到同级 `nvim.backup-时间-随机编号` 目录。
3. 复制配置、使用文档和脚本；不会复制 `.git`、IDE 配置或本地日志。
4. 加上 `-InstallPlugins` 时，调用 Neovim 安装 `lazy-lock.json` 锁定的插件。

脚本不会删除 `nvim-data`，不会安装语言运行时，也不会修改项目文件。复制失败时会把不完整副本移到旁边，并恢复旧配置。

### 常用参数

```powershell
# 仅部署配置，插件在首次启动时安装
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1

# 预览部署操作，不修改目标
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -WhatIf

# 将配置部署到指定目录；该目录不会自动成为 Neovim 的配置目录
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1 -ConfigPath 'D:\backup\nvim-config'
```

如果源目录已经是目标配置目录，脚本会跳过复制。`-InstallPlugins` 会核对 Neovim 的实际配置目录；自定义路径与 Neovim 读取路径不一致时，不会在错误配置上安装插件。

## 3. 首次启动

```powershell
nvim
```

等待插件下载、构建和语言工具安装。完成后执行：

```vim
:Lazy
:Mason
:DevHealth
:checkhealth
```

- `:Lazy`：查看插件是否有安装错误。
- `:Mason`：查看语言服务、格式化工具和调试器；不等于安装 JDK 或 Rust 工具链。
- `:DevHealth`：检查本机开发命令和 LSP。
- `:checkhealth`：查看缺失依赖与兼容问题。

打开项目源码后，语言服务才会启动。首次索引大型 Java 项目可能需要等待。

## 4. 升级与回退

### 更新配置

先在 Neovim 中执行 `:ConfigBackup`，保存并退出。下载仓库的新版本，在新副本中重新运行安装脚本。已有配置会再次备份；自己修改过的配置需要从备份中合并，不能假定升级脚本会自动合并。

### 更新插件

- `:Lazy restore`：安装 / 恢复当前锁文件记录的版本，适合迁移机器或回退。
- `:Lazy update`：更新插件并修改锁文件，适合明确要升级时使用。
- `:Mason`：单独管理语言工具。

### 恢复配置

在编辑器中执行 `:ConfigRestore`，选择已有备份。恢复前会备份当前配置，恢复后重启 Neovim，再按需执行 `:Lazy restore`。

安装脚本生成的备份是另一种备份：关闭 Neovim 后，将当前配置目录改名保存，再把 `nvim.backup-*` 改回 `nvim` 即可。

## 5. 卸载

关闭 Neovim，将配置目录改名或移走即可停用这份配置；需要恢复旧配置时，用安装前的备份替换。运行数据在独立的 `nvim-data` 目录中，包含插件和工作区记录，确认不再需要后再自行清理。
