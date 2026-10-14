-- Java、Rust 的项目隔离与 Windows 调试器路径。
return {
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      handlers = {
        kotlin = function(config)
          config.configurations = {}
          local adapter = vim.fn.stdpath("data") .. "/mason/packages/kotlin-debug-adapter/adapter"
          local java = "C:/My/data/Jir/home/21/temurin/bin/java.exe"
          if vim.fn.filereadable(java) == 1 then
            config.adapters = {
              type = "executable",
              command = java,
              args = { "-cp", adapter .. "/lib/*", "org.javacs.ktda.KDAMainKt" },
            }
          end
          require("mason-nvim-dap").default_setup(config)
        end,
      },
    },
  },
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")
      dap.configurations.kotlin = {
        {
          type = "kotlin",
          request = "attach",
          name = "附加到运行中的 Kotlin JVM（suspend=n）",
          projectRoot = function()
            return require("config.project_tasks").root()
          end,
          hostName = "localhost",
          port = function()
            return tonumber(vim.fn.input("JVM 调试端口：", "5005")) or 5005
          end,
          timeout = 10000,
        },
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- 旧版 Kotlin Language Server 无法解析当前 JDK 26 的版本号，单独用 JDK 21 启动。
      local java21 = "C:/My/data/Jir/home/21/temurin"
      if vim.fn.filereadable(java21 .. "/bin/java.exe") == 1 then
        opts.servers.kotlin_language_server = opts.servers.kotlin_language_server or {}
        opts.servers.kotlin_language_server.cmd_env = {
          JAVA_HOME = java21,
          PATH = java21 .. "/bin;" .. vim.env.PATH,
        }
      end
    end,
  },
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      -- 同名项目使用不同的 JDTLS workspace，避免索引互相覆盖。
      opts.project_name = function(root)
        if not root then
          return nil
        end
        return vim.fs.basename(root) .. "-" .. vim.fn.sha256(vim.fs.normalize(root)):sub(1, 8)
      end
    end,
  },
  {
    "mrcjkb/rustaceanvim",
    config = function(_, opts)
      if LazyVim.has("mason.nvim") then
        local mason = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension"
        local windows = vim.fn.has("win32") == 1
        local codelldb = windows and mason .. "/adapter/codelldb.exe" or vim.fn.exepath("codelldb")
        local liblldb = windows and mason .. "/lldb/bin/liblldb.dll"
          or vim.fn.expand(
            "$MASON/opt/lldb/lib/liblldb" .. (vim.uv.os_uname().sysname == "Linux" and ".so" or ".dylib")
          )
        if vim.fn.filereadable(codelldb) == 1 and vim.fn.filereadable(liblldb) == 1 then
          opts.dap = { adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb, liblldb) }
        end
      end
      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
      if vim.fn.executable("rust-analyzer") == 0 then
        LazyVim.error("rust-analyzer 未安装或不在 PATH 中", { title = "rustaceanvim" })
      end
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { rust = { "rustfmt" } } },
  },
}
