# 开发环境、构建与调试

[返回首页](../README.md)

## 按语言准备环境

| 语言 | 本机需要准备 | 配置中的工具 |
| --- | --- | --- |
| Java | 符合项目要求的 JDK；Maven / Gradle 或项目 wrapper | JDTLS、Java 测试和调试工具 |
| Rust | Rust 工具链、rustfmt、项目所需的链接器 | rust-analyzer、CodeLLDB |
| Kotlin | JDK、Gradle / Maven wrapper | Kotlin Language Server、ktlint、Kotlin 调试适配器 |
| Python | Python 与项目依赖环境 | basedpyright 等语言工具 |
| C / C++ | 编译器和项目构建配置 | clangd |

安装运行时后重新打开终端，再打开项目源码，等待语言服务完成索引。检查 `:Mason`、`:DevHealth` 和 `:checkhealth vim.lsp`。

### 换电脑前需要检查的路径

当前配置包含原机器的工具路径，部署脚本不会凭空安装这些环境：

- `lua/plugins/dev-languages.lua`：Kotlin 语言服务及旧调试适配器使用原机器的 JDK 21 路径 `C:/My/data/Jir/home/21/temurin`。路径存在时才应用这项覆盖；其他机器应按需改成自己的 JDK 路径。旧版 Kotlin Language Server 不适合用 JDK 26 启动。
- `lua/config/signal_project.lua`：Signal-Server 预设 JDK 26 路径。通过 `:SignalSetup` 设置自己的路径。
- `lua/config/options.lua`：Windows 搜索路径、剪贴板和编译器的兼容配置。

项目构建所需的 JDK 与启动语言服务的 JDK 可以不同。

## 通用开发操作

| 操作 | 快捷键 |
| --- | --- |
| 跳转定义 / 引用 | `F12` / `Shift+F12` |
| 重命名并预览 | `F2` |
| 文档 | `K` |
| 格式化 / 代码操作 | `空格 c f` / `空格 c a` |
| 返回 / 前进到跳转位置 | 编辑区 `Alt+←/→` |

Java 格式化由 JDTLS 提供，Rust 使用 rustfmt，Kotlin 使用 ktlint。能否重命名、运行测试和调试取决于语言服务、调试器及项目本身配置。

## 构建和测试

按 `空格 r r` 选择当前项目的任务。配置会识别 Cargo、Maven、Gradle 和 package.json 的常用脚本；优先使用 wrapper。更多任务通过任务模板或项目的 `.vscode/tasks.json` 配置。

| 操作 | 快捷键 / 命令 |
| --- | --- |
| 选择运行 / 构建 / 测试任务 | `空格 r r` / `:ProjectRun` |
| 重新运行上次任务 | `空格 r l` / `:ProjectRerun` |
| 停止任务 | `空格 r s` / `:ProjectStop` |
| 任务列表与输出 | `空格 r o` / `:OverseerOpen` |
| 编译错误列表 | `空格 r e`，`:cnext` / `:cprev` 跳转 |
| 当前测试 / 当前测试类 | `空格 r t` / `空格 r T` |
| 重跑失败测试任务 | `空格 r f` |

启动任务前会保存文件。重跑失败任务是重跑整个测试任务，不是只运行失败的测试用例。Rust 入口打开语言服务提供的测试选择；Kotlin 的 Gradle 入口支持输入测试筛选器。

## 调试

1. 构建项目，保证源码与生成结果一致。
2. 在源码中按 `F9` 设置断点。
3. 按 `F5` 选择配置并启动 / 附加，之后再次按 F5 继续。
4. `空格 d t` 结束调试。

Kotlin 当前采用附加到运行中的 JVM。启动应用时加：

```text
-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=127.0.0.1:5005
```

应用运行后，在 Kotlin 源文件按 F5，选择附加配置并输入端口。旧调试适配器对 `suspend=y` 兼容不佳。

## Signal-Server 专用流程

此预设只针对当前配置识别到的 Signal-Server 项目结构，不是所有 Java 项目的通用启动命令。

### 首次设置

执行 `:SignalSetup`，依次确认：

1. JDK 目录（当前项目预设 JDK 26，实际以项目版本要求为准）。
2. 服务 YAML 配置文件。
3. secrets bundle 文件。

路径保存在 Neovim 状态目录 `project-run`，不会复制 secrets 内容到配置仓库。

### 编译与运行

按 `空格 r r`，选择编译、打包、UtilTest 或 service 测试集。服务启动使用已打包的 JAR，因此先打包，再选择运行服务。

服务会连接 YAML 中指定的数据库和外部依赖，需要先准备对应开发环境。测试全集也可能依赖这些服务，不能把插件安装成功等同于业务环境就绪。

### 调试服务

1. `空格 r r` → 启动服务并监听调试端口。
2. 打开 Java 源文件，等待 JDTLS 就绪。
3. `F9` 设置断点。
4. `空格 r d` 附加调试；默认端口 `127.0.0.1:5005`。

普通 Java 项目的调试仍使用 F5。更多验证边界见 [测试说明](../tests/README.md)。
