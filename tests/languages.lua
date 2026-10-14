local api = vim.api
vim.o.columns = 160
vim.o.lines = 45
api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
require("persistence").stop()
require("config.recent_projects").record = function() end -- 验证样例不进入最近项目历史。
require("lazy").load({ plugins = { "overseer.nvim" } })
local root = vim.fn.stdpath("cache") .. "/workbench-validation"
vim.fn.mkdir(root, "p")
local function write(name, lines)
  vim.fn.mkdir(vim.fs.dirname(root .. "/" .. name), "p")
  vim.fn.writefile(lines, root .. "/" .. name)
end
write("java/pom.xml", {
  '<project xmlns="http://maven.apache.org/POM/4.0.0"><modelVersion>4.0.0</modelVersion><groupId>local.validation</groupId><artifactId>sample</artifactId><version>1</version><properties><maven.compiler.release>21</maven.compiler.release><project.build.sourceEncoding>UTF-8</project.build.sourceEncoding></properties><dependencies><dependency><groupId>org.junit.jupiter</groupId><artifactId>junit-jupiter</artifactId><version>5.11.4</version><scope>test</scope></dependency></dependencies><build><plugins><plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-compiler-plugin</artifactId><version>3.14.1</version></plugin><plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-surefire-plugin</artifactId><version>3.5.6</version></plugin></plugins></build></project>',
})
write("java/src/main/java/sample/Main.java", {
  "package sample;",
  "public class Main {",
  "  public static int sum(int a, int b) { return a + b; }",
  "  public static void main(String[] args) { System.out.println(sum(2, 3)); }",
  "}",
})
write("java/src/test/java/sample/MainTest.java", {
  "package sample;",
  "import org.junit.jupiter.api.Test;",
  "import static org.junit.jupiter.api.Assertions.assertEquals;",
  "class MainTest { @Test void addition() { assertEquals(5, Main.sum(2, 3)); } }",
})
write("rust/Cargo.toml", { "[package]", 'name="workbench_validation"', 'version="0.1.0"', 'edition="2021"' })
write("rust/src/main.rs", {
  "fn sum(a: i32, b: i32) -> i32 { a+b }",
  'fn main() { println!("{}", sum(2,3)); }',
  "#[test]",
  "fn addition() { assert_eq!(sum(2,3),5); }",
})
write("kotlin/settings.gradle.kts", { 'rootProject.name = "workbench-validation"' })
write(
  "kotlin/Main.kt",
  { "fun sum(a: Int, b: Int): Int = a + b", 'fun main() { check(sum(2, 3) == 5); println("KOTLIN_OK") }' }
)
local tasks = require("config.project_tasks")
local function run(name, cmd, args, cwd, env)
  local task =
    assert(tasks.run({ name = name, cmd = cmd, args = args, cwd = cwd, env = env }, { save = false, open = false }))
  assert(
    vim.wait(55000, function()
      return task:is_complete()
    end, 50),
    name .. " timeout"
  )
  local output = table.concat(api.nvim_buf_get_lines(task:get_bufnr(), 0, -1, false), "\n")
  assert(task.status == "SUCCESS", name .. " " .. task.status .. " " .. output)
  print(name .. "_OK")
end
local java = "C:/My/data/Jir/home/21/temurin"
run(
  "MAVEN_JUNIT",
  vim.fn.exepath("mvn"),
  { "-B", "-Dstyle.color=never", "test" },
  root .. "/java",
  { JAVA_HOME = java, PATH = java .. "/bin;" .. vim.env.PATH }
)
run(
  "RUST_BUILD",
  vim.fn.exepath("cargo"),
  { "build", "--offline", "--color=never", "--message-format=short" },
  root .. "/rust"
)
run("RUST_TEST", vim.fn.exepath("cargo"), { "test", "--offline", "--color=never" }, root .. "/rust")
local lib = vim.fn.stdpath("data") .. "/mason/packages/kotlin-language-server/server/lib"
local std = vim.fn.glob(lib .. "/kotlin-stdlib-*.jar", false, true)[1]
assert(std, "Kotlin standard library")
run("KOTLIN_COMPILE", java .. "/bin/java.exe", {
  "-cp",
  lib .. "/*",
  "org.jetbrains.kotlin.cli.jvm.K2JVMCompiler",
  "-no-stdlib",
  "-no-reflect",
  "-classpath",
  std,
  "-d",
  root .. "/kotlin/out",
  root .. "/kotlin/Main.kt",
}, root .. "/kotlin")
run(
  "KOTLIN_ASSERTION_TEST",
  java .. "/bin/java.exe",
  { "-cp", root .. "/kotlin/out;" .. std, "MainKt" },
  root .. "/kotlin"
)
vim.fn.writefile({ root }, vim.fn.stdpath("cache") .. "/workbench-validation-root.txt")
print("ALL_LANGUAGE_BUILDS_TESTS_OK")
vim.cmd("qa!")

