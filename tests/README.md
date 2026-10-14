# 开发工作台验证

2026-10-14 在当前 Windows 主机验证。脚本创建临时 / 缓存样例，不修改业务仓库；首次 Maven 测试可能下载依赖。

| 脚本 | 覆盖范围 |
| --- | --- |
| `workbench.lua` | 原生窗口、未保存内容、窗口布局恢复、Java 运行、中文编译错误跳转、任务取消 |
| `backup.lua` | 在隔离目录中备份、回退、清理新模块，并保留恢复前的备份 |
| `languages.lua` | Maven + JUnit、Cargo 构建和测试、Kotlin 编译与断言测试 |
| `lsp.lua` | 三种语言实际服务的补全、定义跳转、重命名和格式化 |
| `dap.lua` | Java / Rust 入口停止与栈帧、Kotlin 运行中 JVM 的源码断点、继续执行 |
| `ui.py` | 独立 embedded UI 的项目切换、焦点、分屏、终端与中文菜单 |
| `signal_build.lua` | 真实 Signal-Server 的 service 编译及 UtilTest；本机已通过 16 项测试 |
| `signal_profile.lua` | Signal JDK 26、启动参数及仅本机监听的调试配置，不启动服务 |
| `signal_lsp.lua` | 真实 Signal Util.java 的定义跳转和补全 |

在配置目录执行 `./tests/run.ps1`；安装好 Python msgpack 后可加 `-UI` 覆盖 UI 协议。脚本顺序验证，失败时退出并返回非零状态。Java 路径与 Kotlin 编译器来源针对本机；迁移机器时需要调整。构建样例位于 `stdpath('cache')/workbench-validation`。这是本机最小真实项目验证，不等于所有业务项目、框架与远程调试均已验证。

UI 脚本依赖 Python 的 `msgpack`；可安装到系统 Python，或临时目录 `nvim-rpc-deps` 后执行 `python tests/ui.py`。它使用 Neovim UI 协议，验证真实布局事件与输入流程，不是 Windows 桌面截图或外观验收。

加 `-Signal` 会验证本机 `C:/My/code/gitea/temporary/Signal-Server`，需要 JDK 26 和现有 Maven 依赖环境，会更新 target 目录。日志位于 `stdpath('cache')/signal-workbench-validation`。服务启动与真实外部数据库连接未执行；全 service 测试集未作为通过项。

Kotlin 限制：使用 JDK 21 启动旧版适配器。`suspend=n` 的运行中 JVM 附加已验证；`suspend=y` 尚有兼容问题。Gradle wrapper、复杂多模块项目和仅失败用例重跑尚未覆盖；失败测试入口重跑整个任务。
